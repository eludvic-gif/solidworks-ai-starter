import unittest,json,sys,copy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from drawing_review import review
REG=json.loads((ROOT/'standards/registry.json').read_text(encoding='utf-8'))


def fixture():
    return {'units':'mm','regime':'ISO_GPS','projection':'third_angle',
      'source':{'model_id':'synthetic','revision':'A','configuration':'Default','sha256':'a'*64},
      'material':{'designation':'Synthetic test material','specification_basis':'Unit fixture only, not production'},
      'process_basis':'Synthetic test, no fabrication',
      'titleblock':{'document_id':'TEST','revision':'A','title':'Synthetic test','sheet_count':1,'status':'review'},
      'sheets':[{'id':'s1','scale':[2,1],'projection_symbol':'third_angle','projection_layout_reviewed':True,
       'views':[{'id':'front','type':'principal','empty':False,'selection_reason':'Mounting interface visible'}],
       'dimensions':[{'id':'d1','view_id':'front','feature_id':'width','characteristic_id':'width-size',
        'role':'controlling','value_si':.02,'dangling':False,'overridden':False,
        'tolerance':{'kind':'limits','lower_si':.0199,'upper_si':.0201}}]}],
      'requirements':[{'id':'r1','dimension_ids':['d1'],'functional_reason':'Synthetic fit','inspection_method':'Measure opposing faces'}],
      'standards':[{'designation':'ISO 128-3:2022'}],'pdf_all_sheets_reviewed':True,'native_reopen_verified':True}

class DrawingReviewTests(unittest.TestCase):
    def check_failure(self,report,code):
        r=review(report,REG);self.assertEqual(r['status'],'fail');self.assertTrue(any(x['rule']==code and x['status']=='fail' for x in r['findings']))
    def test_no_certification_even_complete_fixture(self):
        r=review(fixture(),REG);self.assertEqual(r['status'],'review_required');self.assertIsNone(r['iso_compliant']);self.assertEqual(r['release'],'NOT_AUTHORIZED')
    def test_empty(self):self.check_failure({},'coverage')
    def test_nonobject(self):self.assertEqual(review([],REG)['status'],'fail')
    def test_no_dimensions_resolve(self):
        r=fixture();r['sheets'][0]['dimensions']=[];self.check_failure(r,'coverage')
    def test_wrong_projection(self):
        r=fixture();r['sheets'][0]['projection_symbol']='first_angle';self.check_failure(r,'projection_evidence')
    def test_duplicate_characteristic(self):
        r=fixture();d=copy.deepcopy(r['sheets'][0]['dimensions'][0]);d['id']='d2';r['sheets'][0]['dimensions'].append(d);self.check_failure(r,'duplicate_control')
    def test_duplicate_dimension_id(self):
        r=fixture();r['sheets'][0]['dimensions']*=2;self.check_failure(r,'identity')
    def test_tolerance_not_decimals(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['tolerance']={};self.check_failure(r,'tolerance_missing')
    def test_reversed_limits(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['tolerance']['lower_si']=.021;self.check_failure(r,'tolerance_limits')
    def test_nonfinite(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['value_si']=float('nan');self.check_failure(r,'dimension_value')
    def test_bool_not_number(self):
        r=fixture();r['sheets'][0]['scale']=[True,1];self.check_failure(r,'scale')
    def test_undefined_datum(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['datum_refs']=['A'];self.check_failure(r,'datum_reference')
    def test_dangling(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['dangling']=True;self.check_failure(r,'associativity')
    def test_reference_does_not_accept(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['role']='reference';self.check_failure(r,'coverage')
    def test_legacy_fails_without_contract(self):
        r=fixture();r['standards']=[{'designation':'ISO 2768-2:1989'}];self.check_failure(r,'legacy_edition')
    def test_legacy_contract_review_not_silent_upgrade(self):
        r=fixture();r['standards']=[{'designation':'ISO 2768-2:1989','legacy_contract':True,'justification':'Existing customer contract'}];self.assertEqual(review(r,REG)['status'],'review_required')
    def test_unknown_standard_unverified(self):
        r=fixture();r['standards']=[{'designation':'ISO 999999:2050'}];self.assertTrue(any(f['rule']=='edition_unverified' for f in review(r,REG)['findings']))
    def test_mixed_regime(self):
        r=fixture();r['standards'].append({'designation':'ASME Y14.5-2018'});self.check_failure(r,'mixed_regime')
    def test_ted_missing_control(self):
        r=fixture();r['sheets'][0]['dimensions'][0]['role']='theoretically_exact';self.check_failure(r,'ted_control')
    def test_principal_rationale(self):
        r=fixture();r['sheets'][0]['views'][0]['selection_reason']='';self.check_failure(r,'principal_view_reason')
    def test_missing_native_reopen(self):
        r=fixture();r['native_reopen_verified']=False;self.check_failure(r,'native_reopen')
    def test_registry_successors(self):
        pairs={(e['old'],e['new']) for e in REG['supersessions']};self.assertIn(('ISO 5459:2011','ISO 5459:2024'),pairs)
        self.assertIn(('ISO 2768-2:1989','ISO 22081:2021'),pairs)
        self.assertFalse(any(a=='ISO 2768-1:1989' for a,b in pairs))
    def test_material_missing(self):
        r=fixture();r.pop('material');self.check_failure(r,'material_definition')
    def test_preview_not_fulltext(self):
        self.assertTrue(all(e.get('full_text_read') is False for e in REG['entries']))

if __name__=='__main__':unittest.main(verbosity=2)
