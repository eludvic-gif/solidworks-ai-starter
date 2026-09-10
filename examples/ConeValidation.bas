Attribute VB_Name = "ConeValidation"
Option Explicit

' Generic SOLIDWORKS API starter macro (example only, no company-specific
' content). Internal VBA macro: no external COM activation, network access
' or PLM access. This macro only creates and inspects a NEW, unsaved part.
' It never saves, closes, exports, or edits a document that already existed
' before it ran, and it never touches PLM, templates, or global settings.
' API geometry uses meters; the input and the report use millimeters.
' Dimensions below (H30 x D10 cone, D5 bore) are synthetic example values
' for exercising the API, not a certified part specification.
Private Const HEIGHT_MM As Double = 30#
Private Const BASE_DIAMETER_MM As Double = 10#
Private Const BORE_DIAMETER_MM As Double = 5#
Private Const BORE_DEPTH_MM As Double = 15#
Private Const WALL_TOL_MM As Double = 0.000001
Private Const VOLUME_REL_TOL As Double = 0.00001
Private Const MM_TO_M As Double = 0.001
Private Const M3_TO_MM3 As Double = 1000000000#
Private Const PART_TYPE As Long = 1
Private Const SOLID_BODY As Long = 0
Private Const ALL_BODIES As Long = -1
Private Const FULLY_CONSTRAINED As Long = 3
' Only the API revision this macro was checked against. Not a claim that
' other revisions are unsupported; see RequireCompatibleRevision below.
Private Const EXPECTED_REVISION_PREFIX As String = "33."

Public Sub main()
    Dim app As Object, doc As Object, plane As Object
    Dim part As SldWorks.PartDoc
    Dim sketchMgr As Object, sketch As Object, sketchFeature As Object
    Dim baseLine As Object, slantLine As Object, axisLine As Object
    Dim radiusDim As Object, heightDim As Object, revolve As Object
    Dim selectionData As Object, mass As Object
    Dim previousDocs As Variant, previousFlags() As Boolean
    Dim templatePath As String, stage As String, message As String
    Dim wall As Double, expectedVolume As Double, actualVolume As Double
    Dim r As Double, h As Double, status As Long, i As Long
    Dim featureError As Long, isWarning As Boolean
    Dim bodies As Variant, editingSketch As Boolean, originalAddToDB As Boolean
    Dim capturedAddToDB As Boolean

    On Error GoTo Failed
    stage = "validating dimensions"
    wall = RadialWallMm(HEIGHT_MM, BASE_DIAMETER_MM, BORE_DIAMETER_MM, BORE_DEPTH_MM)
    expectedVolume = ConeVolumeMm3(HEIGHT_MM, BASE_DIAMETER_MM)
    Set app = Application.SldWorks

    stage = "checking SOLIDWORKS API revision compatibility"
    RequireCompatibleRevision app

    stage = "selecting the local part template"
    templatePath = RequestTemplatePath()
    If Len(templatePath) = 0 Then Exit Sub

    message = "NOVO documento local, sem salvar." & vbCrLf & _
        "Modelo: " & templatePath & vbCrLf & _
        "Cone: altura 30 mm; base diametro 10 mm." & vbCrLf & _
        "Furo solicitado: diametro 5 mm; profundidade 15 mm a partir da base." & vbCrLf & _
        "Parede radial minima prevista: " & Format$(wall, "0.000000") & " mm." & vbCrLf & _
        "FURO BLOQUEADO: parede zero. Nenhum corte sera executado." & vbCrLf & vbCrLf & _
        "Criar somente o cone para inspecao?" & vbCrLf & _
        "Se aparecer entrada de cota, confirme o valor proposto." & vbCrLf & _
        "Nenhum documento existente sera editado. Sem PLM ou rede."
    If MsgBox(message, vbOKCancel Or vbInformation, "Teste local - cone") <> vbOK Then Exit Sub

    previousDocs = app.GetDocuments()
    If IsArray(previousDocs) Then
        ReDim previousFlags(LBound(previousDocs) To UBound(previousDocs))
        For i = LBound(previousDocs) To UBound(previousDocs)
            previousFlags(i) = previousDocs(i).GetSaveFlag()
        Next i
    End If

    stage = "creating a new local document"
    Set doc = app.NewDocument(templatePath, 0, 0#, 0#)
    If doc Is Nothing Then Err.Raise vbObjectError + 101, , "NewDocument returned Nothing."
    If doc.GetType() <> PART_TYPE Then Err.Raise vbObjectError + 102, , "The new document is not a part."
    If Len(doc.GetPathName()) <> 0 Then Err.Raise vbObjectError + 103, , "Expected a new unsaved document."
    RequireActive app, doc
    Set part = doc
    bodies = part.GetBodies2(ALL_BODIES, False)
    If ArrayCount(bodies) <> 0 Then Err.Raise vbObjectError + 104, , "Template contains bodies; stopped before editing."
    Set plane = FindReferencePlane(doc)
    If plane Is Nothing Then Err.Raise vbObjectError + 105, , "No standard reference plane found."
    RequireEmptyTemplate doc

    stage = "creating the cone profile"
    RequireActive app, doc
    doc.ClearSelection2 True
    If Not plane.Select2(False, 0) Then Err.Raise vbObjectError + 106, , "Could not select reference plane."
    Set sketchMgr = doc.SketchManager
    originalAddToDB = sketchMgr.AddToDB
    capturedAddToDB = True
    sketchMgr.InsertSketch True
    Set sketch = sketchMgr.ActiveSketch
    If sketch Is Nothing Then Err.Raise vbObjectError + 107, , "Could not enter sketch."
    editingSketch = True
    sketchMgr.AddToDB = True
    r = BASE_DIAMETER_MM * 0.5 * MM_TO_M
    h = HEIGHT_MM * MM_TO_M
    Set baseLine = sketchMgr.CreateLine(0#, 0#, 0#, r, 0#, 0#)
    Set slantLine = sketchMgr.CreateLine(r, 0#, 0#, 0#, h, 0#)
    Set axisLine = sketchMgr.CreateLine(0#, h, 0#, 0#, 0#, 0#)
    sketchMgr.AddToDB = originalAddToDB
    If baseLine Is Nothing Or slantLine Is Nothing Or axisLine Is Nothing Then
        Err.Raise vbObjectError + 108, , "A sketch line could not be created."
    End If

    ' AddToDB avoids screen snap/inference. Establish the design intent explicitly.
    JoinPoints doc, Endpoint(baseLine, False), Endpoint(slantLine, True)
    JoinPoints doc, Endpoint(slantLine, False), Endpoint(axisLine, True)
    JoinPoints doc, Endpoint(axisLine, False), Endpoint(baseLine, True)
    ConstrainEntity doc, baseLine, "sgHORIZONTAL2D"
    ConstrainEntity doc, axisLine, "sgVERTICAL2D"
    ' Only the origin vertex is fixed, NOT the lines; radius and height remain editable.
    ConstrainEntity doc, Endpoint(baseLine, True), "sgFIXED"

    stage = "adding editable radius and height dimensions"
    Set radiusDim = AddLengthDimension(app, doc, sketch, baseLine, r / 2#, -0.004, "RaioBase", r)
    Set heightDim = AddLengthDimension(app, doc, sketch, axisLine, -0.004, h / 2#, "AlturaCone", h)
    status = sketch.GetConstrainedStatus()
    If status <> FULLY_CONSTRAINED Then
        Err.Raise vbObjectError + 109, , "Sketch is not fully constrained. API status: " & CStr(status)
    End If
    doc.ClearSelection2 True
    sketchMgr.InsertSketch True
    editingSketch = False
    Set sketchFeature = FindProfile(doc)
    If sketchFeature Is Nothing Then Err.Raise vbObjectError + 110, , "Could not find the new profile feature."
    sketchFeature.Name = "Perfil_Cone_Teste"

    stage = "creating the 360 degree solid revolution"
    RequireActive app, doc
    doc.ClearSelection2 True
    If Not sketchFeature.Select2(False, 0) Then Err.Raise vbObjectError + 111, , "Could not select profile (mark 0)."
    Set selectionData = doc.SelectionManager.CreateSelectData()
    selectionData.Mark = 4
    If Not axisLine.Select4(True, selectionData) Then Err.Raise vbObjectError + 112, , "Could not select revolution axis (mark 4)."
    ' Signature verified in installed 2025 interop and help. ThinType is argument 15.
    Set revolve = doc.FeatureManager.FeatureRevolve2( _
        True, True, False, False, False, False, _
        0, 0, 8# * Atn(1#), 0#, False, False, 0#, 0#, _
        0, 0#, 0#, True, False, True)
    If revolve Is Nothing Then Err.Raise vbObjectError + 113, , "FeatureRevolve2 returned Nothing."
    revolve.Name = "Cone_H30_D10_Teste"

    stage = "checking rebuild, dimensions and solid volume"
    If Not doc.EditRebuild3() Then Err.Raise vbObjectError + 114, , "Rebuild did not succeed."
    featureError = revolve.GetErrorCode2(isWarning)
    If featureError <> 0 Then
        Err.Raise vbObjectError + 115, , "Revolve feature status: " & CStr(featureError) & "; warning=" & CStr(isWarning)
    End If
    bodies = part.GetBodies2(ALL_BODIES, False)
    If ArrayCount(bodies) <> 1 Then Err.Raise vbObjectError + 116, , "Expected exactly one body."
    bodies = part.GetBodies2(SOLID_BODY, False)
    If ArrayCount(bodies) <> 1 Then Err.Raise vbObjectError + 117, , "Expected exactly one solid body."
    If Abs(radiusDim.SystemValue - r) > 0.000000001 Then Err.Raise vbObjectError + 118, , "Radius dimension mismatch."
    If Abs(heightDim.SystemValue - h) > 0.000000001 Then Err.Raise vbObjectError + 119, , "Height dimension mismatch."
    doc.ClearSelection2 True
    Set mass = doc.Extension.CreateMassProperty()
    If mass Is Nothing Then Err.Raise vbObjectError + 120, , "Could not read mass properties."
    mass.UseSystemUnits = True
    actualVolume = mass.Volume * M3_TO_MM3
    If Abs(actualVolume - expectedVolume) > expectedVolume * VOLUME_REL_TOL Then
        Err.Raise vbObjectError + 121, , "Volume mismatch. Measured mm3=" & CStr(actualVolume)
    End If
    If Len(doc.GetPathName()) <> 0 Then Err.Raise vbObjectError + 122, , "Document unexpectedly has a saved path."
    If IsArray(previousDocs) Then
        For i = LBound(previousDocs) To UBound(previousDocs)
            If previousDocs(i).GetSaveFlag() <> previousFlags(i) Then
                Err.Raise vbObjectError + 123, , "An existing document's modified flag changed; inspect before proceeding."
            End If
        Next i
    End If
    doc.ClearSelection2 True
    doc.ViewZoomtofit2
    message = "CONE: verificacoes da API aprovadas." & vbCrLf & _
        "Documento novo: " & doc.GetTitle() & vbCrLf & _
        "Altura: " & Format$(heightDim.SystemValue / MM_TO_M, "0.000") & " mm" & vbCrLf & _
        "Diametro da base: " & Format$(2# * radiusDim.SystemValue / MM_TO_M, "0.000") & " mm" & vbCrLf & _
        "Volume medido: " & Format$(actualVolume, "0.000") & " mm3" & vbCrLf & _
        "Volume esperado: " & Format$(expectedVolume, "0.000") & " mm3" & vbCrLf & _
        "Esboco totalmente definido; um corpo solido; reconstrucao sem erro." & vbCrLf & vbCrLf & _
        "FURO: " & BoreClassification(wall) & vbCrLf & _
        "Parede RADIAL no fundo: " & Format$(wall, "0.000000") & " mm." & vbCrLf & _
        "Nao executado. Nenhuma dimensao foi corrigida silenciosamente." & vbCrLf & _
        "Sem salvar, exportar ou acessar PLM. Validacao mecanica nao realizada."
    MsgBox message, vbInformation, "Resultado do teste local"
    Exit Sub

Failed:
    message = "TESTE INTERROMPIDO - sem declarar sucesso." & vbCrLf & _
        "Etapa: " & stage & vbCrLf & "Erro " & CStr(Err.Number) & ": " & Err.Description
    On Error Resume Next
    ' Only restore AddToDB if this run actually captured its original value;
    ' sketchMgr can be non-Nothing for one statement before capture happens.
    If capturedAddToDB Then sketchMgr.AddToDB = originalAddToDB
    ' Leave only the new document/partial feature for inspection; never delete or save.
    If Not doc Is Nothing Then message = message & vbCrLf & "Nova peca mantida para inspecao: " & doc.GetTitle()
    MsgBox message, vbExclamation, "Diagnostico da macro"
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
            Err.Raise vbObjectError + 151, , "Use an absolute local drive path without quotes or wildcards."
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
        Err.Raise vbObjectError + 150, , _
            "SOLIDWORKS API revision '" & revision & "' does not match the checked prefix '" & _
            EXPECTED_REVISION_PREFIX & "'. Stopping before creating any document. Review compatibility first."
    End If
End Sub

Private Sub RequireActive(ByVal app As Object, ByVal expected As Object)
    ' "Is" compares VBA object references: a local, in-process guard only.
    ' It is not the same guarantee as a true COM identity comparison (see
    ' the IUnknown-based check in this kit's .NET connection helper); do
    ' not assume this guard extends across processes or automation hosts.
    Dim current As Object
    Set current = app.ActiveDoc
    If current Is Nothing Then Err.Raise vbObjectError + 130, , "No active document."
    If Not (current Is expected) Then Err.Raise vbObjectError + 131, , "Active document changed. Operation stopped."
End Sub

Private Function FindReferencePlane(ByVal doc As Object) As Object
    Dim feature As Object
    Set feature = doc.FirstFeature()
    Do While Not feature Is Nothing
        If feature.GetTypeName2() = "RefPlane" Then
            Set FindReferencePlane = feature
            Exit Function
        End If
        Set feature = feature.GetNextFeature()
    Loop
End Function

Private Sub RequireEmptyTemplate(ByVal doc As Object)
    Dim feature As Object, featureType As String
    Set feature = doc.FirstFeature()
    Do While Not feature Is Nothing
        featureType = feature.GetTypeName2()
        If featureType = "ProfileFeature" Or featureType = "3DProfileFeature" Or featureType = "Imported" Then
            Err.Raise vbObjectError + 132, , "Template contains existing geometry/sketches."
        End If
        Set feature = feature.GetNextFeature()
    Loop
End Sub

Private Function FindProfile(ByVal doc As Object) As Object
    Dim feature As Object
    Set feature = doc.FirstFeature()
    Do While Not feature Is Nothing
        If feature.GetTypeName2() = "ProfileFeature" Then
            Set FindProfile = feature
            Exit Function
        End If
        Set feature = feature.GetNextFeature()
    Loop
End Function

Private Sub ConstrainEntity(ByVal doc As Object, ByVal entity As Object, ByVal relation As String)
    doc.ClearSelection2 True
    If Not entity.Select4(False, Nothing) Then Err.Raise vbObjectError + 133, , "Cannot select entity for " & relation
    doc.SketchAddConstraints relation
    doc.ClearSelection2 True
End Sub

Private Function Endpoint(ByVal segment As Object, ByVal atStart As Boolean) As Object
    Dim line As SldWorks.SketchLine
    Set line = segment
    If atStart Then
        Set Endpoint = line.GetStartPoint2()
    Else
        Set Endpoint = line.GetEndPoint2()
    End If
End Function

Private Sub JoinPoints(ByVal doc As Object, ByVal first As Object, ByVal second As Object)
    ' Structural ID comparison (not object "Is") for sketch point identity.
    Dim firstId As Variant, secondId As Variant
    firstId = first.GetID()
    secondId = second.GetID()
    If firstId(0) = secondId(0) And firstId(1) = secondId(1) Then Exit Sub
    doc.ClearSelection2 True
    If Not first.Select4(False, Nothing) Then Err.Raise vbObjectError + 134, , "Cannot select first endpoint."
    If Not second.Select4(True, Nothing) Then Err.Raise vbObjectError + 135, , "Cannot select second endpoint."
    doc.SketchAddConstraints "sgCOINCIDENT"
    doc.ClearSelection2 True
End Sub

Private Function AddLengthDimension(ByVal app As Object, ByVal doc As Object, ByVal sketch As Object, _
    ByVal segment As Object, ByVal x As Double, ByVal y As Double, _
    ByVal dimensionName As String, ByVal meters As Double) As Object
    Dim coords(2) As Double, point As Object, math As Object, transform As Object
    Dim displayDim As Object, dimension As Object, position As Variant, result As Long
    RequireActive app, doc
    coords(0) = x: coords(1) = y: coords(2) = 0#
    Set math = app.GetMathUtility()
    Set point = math.CreatePoint(coords)
    Set transform = sketch.ModelToSketchTransform.Inverse()
    Set point = point.MultiplyTransform(transform)
    position = point.ArrayData
    doc.ClearSelection2 True
    If Not segment.Select4(False, Nothing) Then Err.Raise vbObjectError + 136, , "Cannot select line for dimension."
    Set displayDim = doc.AddDimension2(position(0), position(1), position(2))
    If displayDim Is Nothing Then Err.Raise vbObjectError + 137, , "Dimension creation failed/cancelled: " & dimensionName
    Set dimension = displayDim.GetDimension2(0)
    dimension.Name = dimensionName
    result = dimension.SetSystemValue3(meters, 1, Empty)
    If result <> 0 Then Err.Raise vbObjectError + 138, , "Dimension assignment failed: " & dimensionName & "; status=" & CStr(result)
    Set AddLengthDimension = dimension
    doc.ClearSelection2 True
End Function

Private Function ArrayCount(ByVal values As Variant) As Long
    If IsEmpty(values) Then Exit Function
    If IsNull(values) Then Exit Function
    If Not IsArray(values) Then Err.Raise vbObjectError + 139, , "API returned a non-array body list."
    ArrayCount = UBound(values) - LBound(values) + 1
End Function

Private Function RadialWallMm(ByVal height As Double, ByVal baseDiameter As Double, _
    ByVal boreDiameter As Double, ByVal depth As Double) As Double
    If height <= 0# Or baseDiameter <= 0# Or boreDiameter <= 0# Or depth <= 0# Or depth > height Then
        Err.Raise vbObjectError + 140, , "Invalid dimensions: require positive lengths and depth <= height."
    End If
    RadialWallMm = baseDiameter / 2# * (1# - depth / height) - boreDiameter / 2#
End Function

Private Function ConeVolumeMm3(ByVal height As Double, ByVal baseDiameter As Double) As Double
    If height <= 0# Or baseDiameter <= 0# Then Err.Raise vbObjectError + 141, , "Invalid cone dimensions."
    ConeVolumeMm3 = 4# * Atn(1#) * (baseDiameter / 2#) ^ 2 * height / 3#
End Function

Private Function BoreClassification(ByVal wall As Double) As String
    If wall < -WALL_TOL_MM Then
        BoreClassification = "BLOQUEADO - atravessa a lateral."
    ElseIf wall <= WALL_TOL_MM Then
        BoreClassification = "BLOQUEADO - parede zero ou dentro da tolerancia."
    Else
        BoreClassification = "Parede positiva; corte nao implementado nesta etapa."
    End If
End Function

Public Sub TestGeometryOnly()
    ' No SOLIDWORKS document API calls: runs the exact VBA math used by main.
    On Error GoTo Failed
    If Abs(RadialWallMm(30#, 10#, 5#, 15#)) > WALL_TOL_MM Then Err.Raise 5, , "Zero-wall test failed."
    If Abs(RadialWallMm(30#, 10#, 5#, 9#) - 1#) > WALL_TOL_MM Then Err.Raise 5, , "Positive-wall test failed."
    If RadialWallMm(30#, 10#, 5#, 16#) >= 0# Then Err.Raise 5, , "Breakthrough test failed."
    If Abs(ConeVolumeMm3(30#, 10#) - 785.398163397448) > 0.000001 Then Err.Raise 5, , "Volume test failed."
    MsgBox "4 verificacoes matematicas VBA passaram. Nenhum documento acessado.", vbInformation
    Exit Sub
Failed:
    MsgBox "Teste matematico falhou: " & Err.Description, vbExclamation
End Sub
