"""Structured engineering review, NOT an ISO compliance engine or CAD measurement.
Evidence must be supplied by a CAD extractor/reviewer. Internal policy is labelled.
"""
import math
import re


def finite(value):
    return isinstance(value,(int,float)) and not isinstance(value,bool) and math.isfinite(value)


def nonempty(value):
    return isinstance(value,str) and bool(value.strip())


def normalized(value):
    return re.sub(r'\s+',' ',value.replace('‑','-').replace('‐','-')).strip()


def review(report,registry):
    findings=[]
    def issue(code,detail,status='fail',basis='internal_engineering_policy'):
        findings.append({'rule':code,'status':status,'basis':basis,'detail':detail})
    def require(ok,code,detail):
        if not ok:issue(code,detail)
    def records(key,parent=report):
        value=parent.get(key,[])
        if not isinstance(value,list) or any(not isinstance(v,dict) for v in value):
            issue('schema',key+' must be a list of objects');return []
        return value
    def keyed(rows,label):
        result={}
        for row in rows:
            key=row.get('id')
            if not nonempty(key):issue('identity',label+' needs a nonempty string id')
            elif key in result:issue('identity','Duplicate '+label+' id '+key)
            else:result[key]=row
        return result
    if not isinstance(report,dict):
        return {'status':'fail','release':'BLOCKED','iso_compliant':None,'findings':[{'rule':'schema','status':'fail','detail':'Object required'}]}
    require(report.get('units') in ('mm','inch'),'units','Explicit supported units required')
    require(report.get('regime') in ('ISO_GPS','ASME'),'regime','One specification regime required')
    require(report.get('projection') in ('first_angle','third_angle'),'projection','Projection must be declared')
    source=report.get('source',{})
    if not isinstance(source,dict):source={}
    for key in ('model_id','revision','configuration','sha256'):
        require(nonempty(source.get(key)),'source_identity','Source '+key+' required')
    if nonempty(source.get('sha256')):
        require(bool(re.fullmatch('[0-9a-fA-F]{64}',source['sha256'])),'source_identity','SHA256 format invalid')
    material=report.get('material',{})
    if not isinstance(material,dict):material={}
    require(nonempty(material.get('designation')) and nonempty(material.get('specification_basis')),
            'material_definition','Material designation and source/specification basis required for this manufacturing-review profile')
    require(nonempty(report.get('process_basis')),'process_basis','Manufacturing process constraints or explicit process-neutral rationale required')
    title=report.get('titleblock',{})
    if not isinstance(title,dict):title={}
    # Our document-control minimum, not a transcription of ISO7200 fields.
    for key in ('document_id','revision','title','sheet_count','status'):
        value=title.get(key)
        require((isinstance(value,int) and not isinstance(value,bool) and value>0) if key=='sheet_count' else nonempty(value),
                'document_control','Internal titleblock field missing: '+key)
    require(title.get('status')=='review','release_status','This tool handles review documents only')
    sheets=records('sheets');require(bool(sheets),'sheets','At least one sheet required')
    require(title.get('sheet_count')==len(sheets),'sheet_count','Sheet count mismatch')
    keyed(sheets,'sheet')
    views={};dims={};all_dimensions=[]
    for sheet in sheets:
        scale=sheet.get('scale')
        require(isinstance(scale,list) and len(scale)==2 and all(finite(x) and x>0 for x in scale),
                'scale','Positive scale numerator/denominator required; ISO ratio-list compliance not evaluated')
        require(sheet.get('projection_symbol')==report.get('projection') and sheet.get('projection_layout_reviewed') is True,
                'projection_evidence','Projection symbol and reviewed arrangement must agree with declared method')
        local_views=records('views',sheet)
        require(bool(local_views),'views','No view records supplied')
        for key,v in keyed(local_views,'view').items():
            if key in views:issue('identity','View id reused across sheets: '+key)
            views[key]=v
            require(v.get('type') in ('principal','projected','section','detail','auxiliary','isometric'),
                    'view_type','Unsupported/missing view type')
            require(v.get('empty') is False,'empty_view','View must be explicitly checked nonempty')
            if v.get('type')=='principal':
                require(nonempty(v.get('selection_reason')),'principal_view_reason',
                        'Record why principal view best explains function/manufacture/assembly; ISO128-3:2022 4.1 criterion, judgement not automated')
            if v.get('type') in ('section','detail','auxiliary'):
                require(nonempty(v.get('label')) and nonempty(v.get('parent_view')),
                        'view_reference','Derived view requires label and parent view')
                require(v.get('reference_verified') is True,'view_reference','Cut/detail/reference correspondence needs evidence')
        all_dimensions.extend(records('dimensions',sheet))
    dims=keyed(all_dimensions,'dimension')
    require(any(v.get('type')=='principal' for v in views.values()),'principal_view','A principal view must be identified')
    for v in views.values():
        if v.get('type') in ('section','detail','auxiliary'):
            require(v.get('parent_view') in views and v.get('parent_view')!=v.get('id'),'view_reference','Invalid derived-view parent')
    datums=keyed(records('datums'),'datum')
    for datum in datums.values():
        require(nonempty(datum.get('feature_id')) and nonempty(datum.get('functional_reason')) and nonempty(datum.get('inspection_realization')),
                'datum_definition','Datum needs feature, functional rationale and inspection realization, not just a letter')
    controlling={}
    for dim in dims.values():
        require(dim.get('view_id') in views,'dimension_view','Dimension view not found')
        require(nonempty(dim.get('feature_id')),'feature_identity','Dimension needs characteristic/feature id')
        require(finite(dim.get('value_si')),'dimension_value','Dimension value must be finite numeric SI')
        require(dim.get('dangling') is False and dim.get('overridden') is False,'associativity','Explicit associativity/override check required')
        role=dim.get('role')
        require(role in ('controlling','reference','theoretically_exact'),'dimension_role','Dimension role must be explicit')
        if role=='controlling' and nonempty(dim.get('characteristic_id')):
            controlling.setdefault(dim['characteristic_id'],[]).append(dim['id'])
        require(nonempty(dim.get('characteristic_id')),'characteristic_identity','Characteristic id required to detect duplicate controls')
        tolerance=dim.get('tolerance',{})
        if not isinstance(tolerance,dict):tolerance={}
        if role=='controlling':
            kind=tolerance.get('kind')
            if kind=='limits':
                lo,hi=tolerance.get('lower_si'),tolerance.get('upper_si')
                require(finite(lo) and finite(hi) and lo<=hi,'tolerance_limits','Finite ordered acceptance bounds required')
            elif kind=='general':
                require(nonempty(tolerance.get('specification_id')) and tolerance.get('applicability_reviewed') is True,
                        'general_tolerance','Explicit general specification and applicability review required')
                declared={r.get('id') for r in records('general_specifications')}
                require(tolerance.get('specification_id') in declared,'general_tolerance','General specification not defined')
            else:issue('tolerance_missing','Controlling characteristic needs acceptance limits or applicable general specification; decimals are not tolerance')
        if role=='theoretically_exact':
            require(nonempty(dim.get('geometric_control_id')),'ted_control','TED must identify its related geometric control in this internal review profile')
        chain=dim.get('datum_refs',[])
        require(isinstance(chain,list) and all(isinstance(x,str) and x in datums for x in chain),
                'datum_reference','Undefined datum in ordered datum references')
    for characteristic,ids in controlling.items():
        if len(ids)>1:issue('duplicate_control',characteristic+' controlled more than once: '+','.join(ids))
    controls=keyed(records('geometric_controls'),'geometric control')
    for dim in dims.values():
        if dim.get('role')=='theoretically_exact':require(dim.get('geometric_control_id') in controls,'ted_control','TED geometric control not found')
    for control in controls.values():
        require(nonempty(control.get('feature_id')) and nonempty(control.get('characteristic')),'geometric_control','Control needs feature and characteristic')
        require(finite(control.get('tolerance_si')) and control.get('tolerance_si',-1)>=0,'geometric_control','Geometric tolerance invalid')
        chain=control.get('datum_refs',[])
        require(isinstance(chain,list) and all(isinstance(x,str) and x in datums for x in chain),'datum_reference','Control references undefined datum')
        issue('gdt_semantics','Tolerance-zone, modifiers, datum order and applicability require expert review','review_required')
    requirements=keyed(records('requirements'),'requirement')
    require(bool(requirements),'coverage','Functional requirements cannot be empty')
    for requirement in requirements.values():
        ids=requirement.get('dimension_ids',[])
        require(isinstance(ids,list) and bool(ids) and all(isinstance(x,str) and x in dims for x in ids),
                'coverage','Requirement dimensions missing/unresolved')
        if isinstance(ids,list):
            require(any(isinstance(x,str) and x in dims and dims[x].get('role')=='controlling' for x in ids) or
                    nonempty(requirement.get('alternative_acceptance')),'coverage','Reference/TED alone does not establish acceptance criteria')
        require(nonempty(requirement.get('inspection_method')) and nonempty(requirement.get('functional_reason')),
                'inspection','Requirement needs function and inspection method')
    standards=records('standards')
    require(bool(standards),'standards','Explicit edition baseline required, not just an ISO template selector')
    entries=registry.get('entries',[])
    old={normalized(r['old']):r['new'] for r in registry.get('supersessions',[])}
    for declared in standards:
        designation=declared.get('designation','')
        if not nonempty(designation):issue('edition','Empty standard designation');continue
        exact=[e for e in entries if designation in (e.get('designation'),e.get('iso_designation'))]
        historical=normalized(designation) in old or any('withdrawn' in e.get('status_observed','').lower() for e in exact)
        if historical:
            accepted=declared.get('legacy_contract') is True and nonempty(declared.get('justification'))
            issue('legacy_edition','Historical edition requires explicit contractual review; never silently migrate '+designation,
                  'review_required' if accepted else 'fail', 'official_catalogue_or_foreword_plus_internal_policy')
        elif not exact:issue('edition_unverified','No exact edition evidence: '+designation,'not_verified')
        if report.get('regime')=='ISO_GPS' and designation.startswith('ASME'):
            issue('mixed_regime','ISO_GPS baseline includes ASME; segregate and resolve interpretation explicitly')
    for specification in records('general_specifications'):
        require(nonempty(specification.get('definition')) and nonempty(specification.get('scope')) and nonempty(specification.get('exclusions')),
                'general_specification','General specification requires definition, scope and exclusions')
    for texture in records('surface_texture'):
        require(nonempty(texture.get('feature_id')) and nonempty(texture.get('parameter')) and finite(texture.get('limit')) and texture.get('limit',0)>0 and nonempty(texture.get('units')),
                'surface_texture','Texture needs feature, parameter, positive limit and units')
        require(nonempty(texture.get('operator_basis')) and nonempty(texture.get('inspection_method')),
                'surface_texture','Texture filtering/evaluation/default basis and inspection method need review')
        issue('texture_semantics','Profile/areal distinction, acceptance rule and filters require source-backed review','review_required')
    require(report.get('pdf_all_sheets_reviewed') is True,'export_visual','All exported sheets must be reviewed independently')
    require(report.get('native_reopen_verified') is True,'native_reopen','Native reopen and dependency checks required')
    issue('normative_coverage','Available previews do not cover the full normative requirements; no automatic ISO conformance or manufacturing release','not_verified')
    issue('functional_review','Human engineering review remains required even if structured checks pass','review_required')
    failed=any(f['status']=='fail' for f in findings)
    return {'profile':'engineering_v2','status':'fail' if failed else 'review_required',
            'release':'BLOCKED' if failed else 'NOT_AUTHORIZED','iso_compliant':None,
            'findings':findings,'counts':{s:sum(f['status']==s for f in findings) for s in ('fail','review_required','not_verified')},
            'limitations':['Checks supplied metadata, not native geometry or authenticity of reviewer assertions',
                           'Does not validate complete ISO symbol syntax, scale series, line widths or tolerancing semantics']}
