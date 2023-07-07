MyGui := Gui(, "二进制文件转数组")


MyGui.AddGroupBox("Section Hidden xm y0 h12 w400 ", "File Box")
FileText := MyGui.AddEdit(
  "ReadOnly -tabstop xs ys+16 w315 r1", "请选择文件"
)
FileBtn := MyGui.AddButton(
  "Default x+4 ys+15 h25 w80", "选择..."
)
FileBtn.OnEvent("Click", SelectFile)



SaveBtn := MyGui.AddButton(
  "Default xp+0 ys+42 h25 w80", "保存..."
)
SaveBtn.OnEvent("Click", SaveFile)

MyGui.Show("w420 h200")


/* 选取文件 */
SelectFile(*) {
  global
  selectedFileURL := FileSelect(1, , "选择文件", "")
  if (selectedFileURL = "") { 
    return
  } 
  FileText.Value := SelectedFileURL ; 显示文件路径
}

/* 保存文件 */
SaveFile(*) {
  global
  newFileURL := FileSelect("s24", , "选择保存位置", "")
  if (newFileURL = "") { 
    return
  } 

  fileObj := FileOpen(FileText.Value, "r")
  str := ""
  loop fileObj.Length {
    str .= String(fileObj.ReadChar()) . ", "
  }

  newFileObj := FileOpen(newFileURL, "w")
  newFileObj.Write(str)
}

/* 转换 */
File2Arr(fileObj) {

}