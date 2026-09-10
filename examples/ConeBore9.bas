Attribute VB_Name = "ConeBore9"
Option Explicit

' Standalone internal macro (example only, no company-specific content).
' Original ConeValidation.bas remains unchanged; this module duplicates its
' own small helpers on purpose so it can be imported and run independently.
' Native boss-revolve + cut-revolve, both with dimensioned sketches.
' Dimensions below (H30 x D10 cone, D5 bore) are synthetic example values
' for exercising the API, not a certified part specification.
Private Const HEIGHT_MM As Double = 30#
Private Const BASE_DIAMETER_MM As Double = 10#
Private Const BORE_DIAMETER_MM As Double = 5#
Private Const BORE_DEPTH_MM As Double = 9#
Private Const WALL_TOL_MM As Double = 0.000001
Private Const REL_TOL As Double = 0.00001
Private Const LENGTH_TOL_M As Double = 0.000000001
Private Const MM_TO_M As Double = 0.001
Private Const M3_TO_MM3 As Double = 1000000000#
' Only the API revision this macro was checked against. Not a claim that
' other revisions are unsupported; see RequireCompatibleRevision below.
Private Const EXPECTED_REVISION_PREFIX As String = "33."

Public Sub RunConeBore9()
    Dim app As Object, doc As Object, plane As Object, mgr As Object
    Dim part As SldWorks.PartDoc
    Dim profile As Object, boreProfile As Object, cone As Object, cut As Object
    Dim sketch As Object, baseLine As Object, side As Object, top As Object, axis As Object
    Dim coneRadius As Object, coneHeight As Object, boreRadius As Object, boreDepth As Object
    Dim radius As Double, height As Double, holeRadius As Double, depth As Double
    Dim wall As Double, coneExpected As Double, finalExpected As Double
    Dim coneMeasured As Double, finalMeasured As Double
    Dim savedAddToDB As Boolean, capturedAddToDB As Boolean
    Dim bodies As Variant, previousDocs As Variant, previousFlags() As Boolean
    Dim templatePath As String, stage As String, report As String, i As Long
    On Error GoTo Failed

    stage = "validating requested dimensions before creating a document"
    wall = WallMm(HEIGHT_MM, BASE_DIAMETER_MM, BORE_DIAMETER_MM, BORE_DEPTH_MM)
    If wall <= WALL_TOL_MM Then Err.Raise vbObjectError + 200, , "Bore blocked: zero/negative radial wall. No document created."
    coneExpected = ConeVolume(HEIGHT_MM, BASE_DIAMETER_MM)
    finalExpected = NetVolume(HEIGHT_MM, BASE_DIAMETER_MM, BORE_DIAMETER_MM, BORE_DEPTH_MM)
    radius = BASE_DIAMETER_MM / 2# * MM_TO_M
    height = HEIGHT_MM * MM_TO_M
    holeRadius = BORE_DIAMETER_MM / 2# * MM_TO_M
    depth = BORE_DEPTH_MM * MM_TO_M
    Set app = Application.SldWorks

    stage = "checking SOLIDWORKS API revision compatibility"
    RequireCompatibleRevision app

    stage = "selecting the local part template"
    templatePath = RequestTemplatePath()
    If Len(templatePath) = 0 Then Exit Sub

    report = "Criar NOVA peca local, sem salvar." & vbCrLf & _
        "Modelo: " & templatePath & vbCrLf & _
        "Cone: altura 30 mm, base diametro 10 mm." & vbCrLf & _
        "Furo: diametro 5 mm, profundidade 9 mm, fundo plano, partindo da base." & vbCrLf & _
        "Parede RADIAL minima prevista: " & Format$(wall, "0.000") & " mm." & vbCrLf & _
        "Volume final esperado: " & Format$(finalExpected, "0.000") & " mm3." & vbCrLf & _
        "Sera executado um CORTE POR REVOLUCAO de 360 graus." & vbCrLf & _
        "Nenhuma peca existente sera editada. Sem salvar, exportar ou acessar PLM." & vbCrLf & _
        "Se forem pedidas cotas: raios 5 e 2,5 mm; comprimentos 30 e 9 mm." & vbCrLf & vbCrLf & _
        "Continuar?"
    If MsgBox(report, vbOKCancel Or vbInformation, "Teste local - cone com furo") <> vbOK Then Exit Sub
    previousDocs = app.GetDocuments()
    If IsArray(previousDocs) Then
        ReDim previousFlags(LBound(previousDocs) To UBound(previousDocs))
        For i = LBound(previousDocs) To UBound(previousDocs)
            previousFlags(i) = previousDocs(i).GetSaveFlag()
        Next i
    End If

    stage = "creating a separate unsaved local part"
    Set doc = app.NewDocument(templatePath, 0, 0#, 0#)
    If doc Is Nothing Then Err.Raise vbObjectError + 202, , "NewDocument returned Nothing."
    If doc.GetType() <> 1 Or Len(doc.GetPathName()) <> 0 Then Err.Raise vbObjectError + 203, , "Expected a new unsaved part."
    RequireActive app, doc
    Set part = doc
    bodies = part.GetBodies2(-1, False)
    If CountArray(bodies) <> 0 Then Err.Raise vbObjectError + 204, , "Template contains geometry."
    Set plane = EmptyTemplatePlane(doc)
    If plane Is Nothing Then Err.Raise vbObjectError + 205, , "No reference plane found."
    Set mgr = doc.SketchManager
    savedAddToDB = mgr.AddToDB
    capturedAddToDB = True

    stage = "creating the cone sketch"
    Set sketch = BeginProfile(app, doc, plane)
    mgr.AddToDB = True
    Set baseLine = mgr.CreateLine(0#, 0#, 0#, radius, 0#, 0#)
    Set side = mgr.CreateLine(radius, 0#, 0#, 0#, height, 0#)
    Set axis = mgr.CreateLine(0#, height, 0#, 0#, 0#, 0#)
    mgr.AddToDB = savedAddToDB
    CheckLine baseLine: CheckLine side: CheckLine axis
    JoinPoints doc, EndPoint(baseLine, False), EndPoint(side, True)
    JoinPoints doc, EndPoint(side, False), EndPoint(axis, True)
    JoinPoints doc, EndPoint(axis, False), EndPoint(baseLine, True)
    Relation doc, baseLine, "sgHORIZONTAL2D"
    Relation doc, axis, "sgVERTICAL2D"
    Relation doc, EndPoint(baseLine, True), "sgFIXED"
    Set coneRadius = LengthDimension(app, doc, sketch, baseLine, radius / 2#, -0.004, "RaioBase", radius)
    Set coneHeight = LengthDimension(app, doc, sketch, axis, -0.004, height / 2#, "AlturaCone", height)
    Set profile = FinishProfile(doc, sketch, "Perfil_Cone_H30_D10")
    stage = "creating and checking the cone revolution"
    Set cone = RevolveProfile(app, doc, profile, axis, False)
    cone.Name = "Cone_H30_D10"
    CheckFeature doc, cone
    coneMeasured = SolidVolume(doc, part)
    NearVolume coneMeasured, coneExpected
    NearLength coneRadius.SystemValue, radius
    NearLength coneHeight.SystemValue, height

    stage = "creating the bore rectangle on the same reference plane"
    Set sketch = BeginProfile(app, doc, plane)
    mgr.AddToDB = True
    Set baseLine = mgr.CreateLine(0#, 0#, 0#, holeRadius, 0#, 0#)
    Set side = mgr.CreateLine(holeRadius, 0#, 0#, holeRadius, depth, 0#)
    Set top = mgr.CreateLine(holeRadius, depth, 0#, 0#, depth, 0#)
    Set axis = mgr.CreateLine(0#, depth, 0#, 0#, 0#, 0#)
    mgr.AddToDB = savedAddToDB
    CheckLine baseLine: CheckLine side: CheckLine top: CheckLine axis
    JoinPoints doc, EndPoint(baseLine, False), EndPoint(side, True)
    JoinPoints doc, EndPoint(side, False), EndPoint(top, True)
    JoinPoints doc, EndPoint(top, False), EndPoint(axis, True)
    JoinPoints doc, EndPoint(axis, False), EndPoint(baseLine, True)
    Relation doc, baseLine, "sgHORIZONTAL2D"
    Relation doc, top, "sgHORIZONTAL2D"
    Relation doc, side, "sgVERTICAL2D"
    Relation doc, axis, "sgVERTICAL2D"
    Relation doc, EndPoint(baseLine, True), "sgFIXED"
    Set boreRadius = LengthDimension(app, doc, sketch, baseLine, holeRadius / 2#, -0.003, "RaioFuro", holeRadius)
    Set boreDepth = LengthDimension(app, doc, sketch, axis, -0.003, depth / 2#, "ProfundidadeFuro", depth)
    Set boreProfile = FinishProfile(doc, sketch, "Perfil_Furo_D5_P9")

    stage = "cutting the blind cylindrical bore"
    ' Guard uses the dimensions actually assigned to the CAD sketches.
    wall = WallMm(coneHeight.SystemValue / MM_TO_M, 2# * coneRadius.SystemValue / MM_TO_M, _
                  2# * boreRadius.SystemValue / MM_TO_M, boreDepth.SystemValue / MM_TO_M)
    If wall <= WALL_TOL_MM Then Err.Raise vbObjectError + 206, , "Measured dimensions would leave zero/negative wall. Cut not executed."
    Set cut = RevolveProfile(app, doc, boreProfile, axis, True)
    cut.Name = "Furo_Cego_D5_P9"
    CheckFeature doc, cone
    CheckFeature doc, cut

    stage = "checking final solid, dimensions, cylindrical surface and volume"
    finalMeasured = SolidVolume(doc, part)
    NearVolume finalMeasured, finalExpected
    NearVolume coneMeasured - finalMeasured, coneExpected - finalExpected
    NearLength coneRadius.SystemValue, radius
    NearLength coneHeight.SystemValue, height
    NearLength boreRadius.SystemValue, holeRadius
    NearLength boreDepth.SystemValue, depth
    VerifyCylinder part, holeRadius
    If Len(doc.GetPathName()) <> 0 Then Err.Raise vbObjectError + 207, , "Document unexpectedly has a saved path."
    If IsArray(previousDocs) Then
        For i = LBound(previousDocs) To UBound(previousDocs)
            If previousDocs(i).GetSaveFlag() <> previousFlags(i) Then
                Err.Raise vbObjectError + 208, , "An existing document's modified flag changed; inspect before proceeding."
            End If
        Next i
    End If
    doc.ClearSelection2 True
    doc.ViewZoomtofit2
    report = "CONE + FURO: verificacoes da API aprovadas." & vbCrLf & _
        "Nova peca: " & doc.GetTitle() & " (sem salvar)." & vbCrLf & _
        "Cone: altura 30 mm; base diametro 10 mm." & vbCrLf & _
        "Furo cego: diametro 5 mm; profundidade 9 mm." & vbCrLf & _
        "Parede RADIAL calculada das cotas: " & Format$(wall, "0.000") & " mm." & vbCrLf & _
        "Volume inicial: " & Format$(coneMeasured, "0.000") & " mm3." & vbCrLf & _
        "Volume final medido: " & Format$(finalMeasured, "0.000") & " mm3." & vbCrLf & _
        "Volume final esperado: " & Format$(finalExpected, "0.000") & " mm3." & vbCrLf & _
        "Volume retirado: " & Format$(coneMeasured - finalMeasured, "0.000") & " mm3." & vbCrLf & _
        "Dois esbocos totalmente definidos; um corpo solido; reconstrucao sem erro." & vbCrLf & _
        "Face cilindrica com raio 2,5 mm confirmada." & vbCrLf & _
        "Inspecione a abertura pela base ou use vista de secao." & vbCrLf & _
        "Sem salvar/exportar/PLM. Nao avalia resistencia mecanica."
    MsgBox report, vbInformation, "Resultado - cone com furo de 9 mm"
    Exit Sub
Failed:
    report = "TESTE INTERROMPIDO. Nao declarar sucesso." & vbCrLf & _
             "Etapa: " & stage & vbCrLf & "Erro " & CStr(Err.Number) & ": " & Err.Description
    On Error Resume Next
    ' Only restore AddToDB if this run actually captured its original value.
    If capturedAddToDB Then mgr.AddToDB = savedAddToDB
    If Not doc Is Nothing Then report = report & vbCrLf & "Nova peca parcial mantida para inspecao: " & doc.GetTitle()
    MsgBox report, vbExclamation, "Diagnostico - cone com furo"
End Sub

Private Function RequestTemplatePath() As String
    ' InputBox accepts Unicode text; an empty/cancelled entry aborts before
    ' any document is created. No directory search is performed: guessing
    ' the wrong template silently is worse than asking once, explicitly.
    Dim raw As String, candidate As String
    raw = InputBox$( _
        "Caminho completo de um template de peca (.PRTDOT) local." & vbCrLf & _
        "SOLIDWORKS revisao " & EXPECTED_REVISION_PREFIX & "x (constante deste modulo)." & vbCrLf & _
        "Deixe vazio e cancele/OK para abortar sem criar documento.", _
        "Teste local - template de peca")
    candidate = Trim$(raw)
    If Len(candidate) > 0 Then
        If Len(candidate) < 3 Or Mid$(candidate, 2, 2) <> ":\" Or _
           InStr(candidate, "*") > 0 Or InStr(candidate, "?") > 0 Then
            Err.Raise vbObjectError + 240, , "Use an absolute local drive path without quotes or wildcards."
        End If
    End If
    If Len(candidate) = 0 Then
        RequestTemplatePath = ""
        Exit Function
    End If
    If LCase$(Right$(candidate, 7)) <> ".prtdot" Then
        MsgBox "Caminho nao termina em .PRTDOT:" & vbCrLf & candidate & vbCrLf & _
            "Nenhum documento sera criado.", vbExclamation, "Teste local - template de peca"
        RequestTemplatePath = ""
        Exit Function
    End If
    If Len(Dir$(candidate, vbNormal Or vbReadOnly Or vbHidden Or vbSystem)) = 0 Then
        MsgBox "Arquivo nao encontrado:" & vbCrLf & candidate & vbCrLf & _
            "Nenhum documento sera criado. Nenhuma busca automatica foi realizada.", _
            vbExclamation, "Teste local - template de peca"
        RequestTemplatePath = ""
        Exit Function
    End If
    RequestTemplatePath = candidate
End Function

Private Sub RequireCompatibleRevision(ByVal app As Object)
    ' Default behavior is to stop (lock) on a revision mismatch and say so
    ' plainly. This is not a claim that other revisions do or do not work;
    ' it only means this macro was checked against EXPECTED_REVISION_PREFIX.
    Dim revision As String
    revision = app.RevisionNumber()
    If Left$(revision, Len(EXPECTED_REVISION_PREFIX)) <> EXPECTED_REVISION_PREFIX Then
        Err.Raise vbObjectError + 209, , _
            "SOLIDWORKS API revision '" & revision & "' does not match the checked prefix '" & _
            EXPECTED_REVISION_PREFIX & "'. Stopping before creating any document. Review compatibility first."
    End If
End Sub

Private Sub RequireActive(ByVal app As Object, ByVal doc As Object)
    ' "Is" compares VBA object references: a local, in-process guard only.
    ' It is not the same guarantee as a true COM identity comparison (see
    ' the IUnknown-based check in this kit's .NET connection helper); do
    ' not assume this guard extends across processes or automation hosts.
    Dim current As Object
    Set current = app.ActiveDoc
    If current Is Nothing Then Err.Raise vbObjectError + 210, , "No active document."
    If Not (current Is doc) Then Err.Raise vbObjectError + 211, , "Active document changed; operation stopped."
End Sub

Private Function EmptyTemplatePlane(ByVal doc As Object) As Object
    Dim feature As Object, firstPlane As Object, kind As String
    Set feature = doc.FirstFeature()
    Do While Not feature Is Nothing
        kind = feature.GetTypeName2()
        If kind = "ProfileFeature" Or kind = "3DProfileFeature" Or kind = "Imported" Then
            Err.Raise vbObjectError + 212, , "Template has pre-existing sketches/geometry."
        End If
        If kind = "RefPlane" And firstPlane Is Nothing Then Set firstPlane = feature
        Set feature = feature.GetNextFeature()
    Loop
    Set EmptyTemplatePlane = firstPlane
End Function

Private Function BeginProfile(ByVal app As Object, ByVal doc As Object, ByVal plane As Object) As Object
    Dim createdSketch As Object
    RequireActive app, doc
    doc.ClearSelection2 True
    If Not plane.Select2(False, 0) Then Err.Raise vbObjectError + 213, , "Cannot select reference plane."
    doc.SketchManager.InsertSketch True
    Set createdSketch = doc.SketchManager.ActiveSketch
    If createdSketch Is Nothing Then Err.Raise vbObjectError + 214, , "Cannot enter sketch."
    Set BeginProfile = createdSketch
End Function

Private Function FinishProfile(ByVal doc As Object, ByVal sketch As Object, ByVal newName As String) As Object
    Dim feature As Object, candidate As Object
    Dim actualSketch As Object, status As Long
    status = sketch.GetConstrainedStatus()
    If status <> 3 Then Err.Raise vbObjectError + 215, , "Sketch not fully constrained: " & CStr(status)
    doc.ClearSelection2 True
    doc.SketchManager.InsertSketch True
    Set feature = doc.FirstFeature()
    Do While Not feature Is Nothing
        If feature.GetTypeName2() = "ProfileFeature" Then
            Set actualSketch = feature.GetSpecificFeature2()
            If actualSketch Is sketch Then
                Set candidate = feature
                Exit Do
            End If
        End If
        Set feature = feature.GetNextFeature()
    Loop
    If candidate Is Nothing Then Err.Raise vbObjectError + 216, , "Cannot locate exact newly-created sketch feature."
    candidate.Name = newName
    Set FinishProfile = candidate
End Function

Private Function RevolveProfile(ByVal app As Object, ByVal doc As Object, _
    ByVal profile As Object, ByVal axis As Object, ByVal isCut As Boolean) As Object
    Dim sel As Object, feature As Object
    RequireActive app, doc
    doc.ClearSelection2 True
    If Not profile.Select2(False, 0) Then Err.Raise vbObjectError + 217, , "Cannot select profile with mark 0."
    Set sel = doc.SelectionManager.CreateSelectData()
    sel.Mark = 4
    If Not axis.Select4(True, sel) Then Err.Raise vbObjectError + 218, , "Cannot select axis with mark 4."
    ' Documented 20-argument API; argument 4 enables cut, argument 15 is ThinType.
    Set feature = doc.FeatureManager.FeatureRevolve2( _
        True, True, False, isCut, False, False, _
        0, 0, 8# * Atn(1#), 0#, False, False, 0#, 0#, _
        0, 0#, 0#, True, False, True)
    If feature Is Nothing Then Err.Raise vbObjectError + 219, , "Revolve returned Nothing; isCut=" & CStr(isCut)
    Set RevolveProfile = feature
End Function

Private Sub CheckFeature(ByVal doc As Object, ByVal feature As Object)
    Dim code As Long, warning As Boolean
    If Not doc.EditRebuild3() Then Err.Raise vbObjectError + 220, , "Rebuild failed."
    code = feature.GetErrorCode2(warning)
    If code <> 0 Then Err.Raise vbObjectError + 221, , feature.Name & ": status=" & CStr(code) & "; warning=" & CStr(warning)
End Sub

Private Function SolidVolume(ByVal doc As Object, ByVal part As SldWorks.PartDoc) As Double
    Dim bodies As Variant, mass As Object
    bodies = part.GetBodies2(-1, False)
    If CountArray(bodies) <> 1 Then Err.Raise vbObjectError + 222, , "Expected one body total."
    bodies = part.GetBodies2(0, False)
    If CountArray(bodies) <> 1 Then Err.Raise vbObjectError + 223, , "Expected one solid body."
    doc.ClearSelection2 True
    Set mass = doc.Extension.CreateMassProperty()
    If mass Is Nothing Then Err.Raise vbObjectError + 224, , "No mass property result."
    mass.UseSystemUnits = True
    SolidVolume = mass.Volume * M3_TO_MM3
End Function

Private Sub VerifyCylinder(ByVal part As SldWorks.PartDoc, ByVal expectedRadius As Double)
    Dim bodies As Variant, faces As Variant, params As Variant
    Dim body As Object, face As Object, surface As Object, i As Long, found As Long
    bodies = part.GetBodies2(0, False)
    Set body = bodies(LBound(bodies))
    faces = body.GetFaces()
    If Not IsArray(faces) Then Err.Raise vbObjectError + 225, , "No faces returned."
    For i = LBound(faces) To UBound(faces)
        Set face = faces(i)
        Set surface = face.GetSurface()
        If surface.IsCylinder() Then
            params = surface.CylinderParams
            ' Official ISurface.CylinderParams: origin(0..2), axis(3..5), radius(6), meters.
            NearLength CDbl(params(6)), expectedRadius
            found = found + 1
        End If
    Next i
    If found = 0 Then Err.Raise vbObjectError + 226, , "No cylindrical bore surface found."
End Sub

Private Sub NearVolume(ByVal actual As Double, ByVal expected As Double)
    If Abs(actual - expected) > expected * REL_TOL Then
        Err.Raise vbObjectError + 227, , "Volume mismatch: measured=" & CStr(actual) & "; expected=" & CStr(expected) & " mm3."
    End If
End Sub

Private Sub NearLength(ByVal actual As Double, ByVal expected As Double)
    If Abs(actual - expected) > LENGTH_TOL_M Then Err.Raise vbObjectError + 228, , "Length mismatch (meters): " & CStr(actual) & "; expected=" & CStr(expected)
End Sub

Private Sub CheckLine(ByVal segment As Object)
    If segment Is Nothing Then Err.Raise vbObjectError + 229, , "Could not create a profile line."
End Sub

Private Function EndPoint(ByVal segment As Object, ByVal atStart As Boolean) As Object
    Dim line As SldWorks.SketchLine
    Set line = segment
    If atStart Then
        Set EndPoint = line.GetStartPoint2()
    Else
        Set EndPoint = line.GetEndPoint2()
    End If
End Function

Private Sub JoinPoints(ByVal doc As Object, ByVal first As Object, ByVal second As Object)
    ' Structural ID comparison (not object "Is") for sketch point identity.
    Dim a As Variant, b As Variant
    a = first.GetID(): b = second.GetID()
    If a(0) = b(0) And a(1) = b(1) Then Exit Sub
    doc.ClearSelection2 True
    If Not first.Select4(False, Nothing) Then Err.Raise vbObjectError + 230, , "Cannot select first point."
    If Not second.Select4(True, Nothing) Then Err.Raise vbObjectError + 231, , "Cannot select second point."
    doc.SketchAddConstraints "sgCOINCIDENT"
    doc.ClearSelection2 True
End Sub

Private Sub Relation(ByVal doc As Object, ByVal entity As Object, ByVal kind As String)
    doc.ClearSelection2 True
    If Not entity.Select4(False, Nothing) Then Err.Raise vbObjectError + 232, , "Cannot select constraint entity."
    doc.SketchAddConstraints kind
    doc.ClearSelection2 True
End Sub

Private Function LengthDimension(ByVal app As Object, ByVal doc As Object, ByVal sketch As Object, _
    ByVal segment As Object, ByVal x As Double, ByVal y As Double, ByVal name As String, ByVal value As Double) As Object
    Dim xyz(2) As Double, math As Object, point As Object, transform As Object
    Dim position As Variant, display As Object, dimension As Object, result As Long
    RequireActive app, doc
    xyz(0) = x: xyz(1) = y: xyz(2) = 0#
    Set math = app.GetMathUtility()
    Set point = math.CreatePoint(xyz)
    Set transform = sketch.ModelToSketchTransform.Inverse()
    Set point = point.MultiplyTransform(transform)
    position = point.ArrayData
    doc.ClearSelection2 True
    If Not segment.Select4(False, Nothing) Then Err.Raise vbObjectError + 233, , "Cannot select dimension entity."
    Set display = doc.AddDimension2(position(0), position(1), position(2))
    If display Is Nothing Then Err.Raise vbObjectError + 234, , "Dimension failed/cancelled: " & name
    Set dimension = display.GetDimension2(0)
    dimension.Name = name
    result = dimension.SetSystemValue3(value, 1, Empty)
    If result <> 0 Then Err.Raise vbObjectError + 235, , "Dimension assignment failed: " & name & "; status=" & CStr(result)
    Set LengthDimension = dimension
    doc.ClearSelection2 True
End Function

Private Function CountArray(ByVal values As Variant) As Long
    If IsEmpty(values) Or IsNull(values) Then Exit Function
    If Not IsArray(values) Then Err.Raise vbObjectError + 236, , "Expected array."
    CountArray = UBound(values) - LBound(values) + 1
End Function

Private Function WallMm(ByVal height As Double, ByVal diameter As Double, ByVal hole As Double, ByVal depth As Double) As Double
    If height <= 0# Or diameter <= 0# Or hole <= 0# Or depth <= 0# Or depth > height Then
        Err.Raise vbObjectError + 237, , "Invalid positive dimensions/depth."
    End If
    WallMm = diameter / 2# * (1# - depth / height) - hole / 2#
End Function

Private Function ConeVolume(ByVal height As Double, ByVal diameter As Double) As Double
    If height <= 0# Or diameter <= 0# Then Err.Raise vbObjectError + 238, , "Invalid cone dimensions."
    ConeVolume = 4# * Atn(1#) * (diameter / 2#) ^ 2 * height / 3#
End Function

Private Function NetVolume(ByVal height As Double, ByVal diameter As Double, ByVal hole As Double, ByVal depth As Double) As Double
    If WallMm(height, diameter, hole, depth) <= WALL_TOL_MM Then Err.Raise vbObjectError + 239, , "Bore blocked by wall check."
    NetVolume = ConeVolume(height, diameter) - 4# * Atn(1#) * (hole / 2#) ^ 2 * depth
End Function

Public Sub TestBore9Math()
    On Error GoTo Failed
    If Abs(WallMm(30#, 10#, 5#, 9#) - 1#) > WALL_TOL_MM Then Err.Raise 5, , "Wall test failed."
    If Abs(NetVolume(30#, 10#, 5#, 9#) - 608.683576633022) > 0.000001 Then Err.Raise 5, , "Net volume test failed."
    If Abs(WallMm(30#, 10#, 5#, 15#)) > WALL_TOL_MM Then Err.Raise 5, , "Zero-wall test failed."
    If WallMm(30#, 10#, 5#, 16#) >= 0# Then Err.Raise 5, , "Breakthrough test failed."
    MsgBox "4 verificacoes matematicas VBA passaram. Nenhuma peca acessada.", vbInformation
    Exit Sub
Failed:
    MsgBox "Teste matematico falhou: " & Err.Description, vbExclamation
End Sub
