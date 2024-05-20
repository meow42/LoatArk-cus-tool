/* 定义全局参数 */
Version := "1.5" ; 版本号
GUIWidth := 420 ; 窗体宽度
GUIHeight := 142 ; 窗体高度
Region := [
  " CHN - 国服", 
  " JPN - 日服", 
  " KOR - 韩服", 
  " RUS - 俄服",
  " TWN - 台服",
  " USA - Steam"
] ; 服务器区域字串数组
CusHeadNum2Str := "30-1-13000" ; 捏脸文件头转字符串
CusFileObj := unset ; 存放文件对象
IsFileReady := false ; 是否已选取合法文件


    
/* 窗体定义 开始 */
MyGui := Gui(, "LostArk 捏脸数据转换工具 - v" . Version)
MyGui.SetFont("s11")
InnerWidth := GUIWidth - MyGui.MarginX * 2 ; 窗体内部的可用宽度

; 文件选取区域 
FileBoxHeight := 42
FileSelectBtnWidth := 80
MyGui.AddGroupBox("Section Hidden xm y0 h" FileBoxHeight " w" InnerWidth, "File Box")
CusFileText := MyGui.AddEdit(
  "ReadOnly -tabstop xs ys+16 w" (InnerWidth - FileSelectBtnWidth - 3) " r1", 
  "请选择捏脸数据文件"
)
CusFileBtn := MyGui.AddButton("Default x+4 ys+15 h25 w" FileSelectBtnWidth, "选择...")
CusFileBtn.OnEvent("Click", SelectCusFile)
MyGui.OnEvent("DropFiles", DropFileEvent) ; 拖入文件上传

; 数据转换操作区域
ConvertBox := MyGui.AddGroupBox("Section Hidden xm ys" FileBoxHeight " h150 w" InnerWidth, "Convert Box")
DDLWidth := 140, SpanWidth := 29 ; 控制列宽
Row1Y := 9, Row2Y := 27         ; 控制行距

; 提示文本
MyGui.AddText("xs ys+" Row1Y " w" DDLWidth, "已选取的数据：")
MyGui.AddText("x+0 ys+" Row2Y + 4 " w" SpanWidth, " →")
MyGui.AddText("x+0 ys+" Row1Y " w" DDLWidth, "想要转换成为：")

; 转换选项
RegionBeforeList := MyGui.AddDropDownList(
  "Disabled -tabstop xs ys+" Row2Y " r" Region.Length " w" DDLWidth, Region
)
RegionAfterList := MyGui.AddDropDownList(
  "Choose1 xs+" DDLWidth + SpanWidth " ys+" Row2Y " r" Region.Length " w" DDLWidth, Region
)

; 操作按钮
ConvertBtn := MyGui.AddButton(
  "Default w80 h25 xs" InnerWidth - 79 " ys+" Row2Y - 1, "另存为..."
)
ConvertBtn.OnEvent("Click", SaveCusFile)

; 数据转换-帮助提示


; 底部信息
MyGui.SetFont("s9")
MyGui.AddLink(
  "right xs ym+" (GUIHeight - 26) " w" InnerWidth, 
  '本工具由B站UP主<a href="https://space.bilibili.com/18422589">@喵闪闪嗷呜一声</a>定制，' .
  '更多信息请访问<a href="https://gitee.com/meowshanshan/lostark-cus-converter">项目Git仓库</a>'
)


; 显示窗体
update()
MyGui.Show("w" . GUIWidth . " h" . GUIHeight)

/* 窗体定义 结束 */

/* 文件拖放事件 */
DropFileEvent(guiObj, guiCtrlObj, fileArray, x, y) {
  global
  if (CusFileBtn.Enabled) {
    CheckCusFile(fileArray[1])
  }
}

/* 选取文件 */
SelectCusFile(*) {
  ; 弹出文件选取框
  selectedFileURL := FileSelect(
    1, , "选择捏脸数据文件", "捏脸数据 (*.cus)"
  )
  CheckCusFile(selectedFileURL)
}

/* 处理选取的文件 */
CheckCusFile(selectedFileURL := "") {
  global

  if (selectedFileURL = "") { 
    return
  } 
  
  CusFileText.Value := selectedFileURL ; 显示文件路径
  IsFileReady := false
  CusFileObj := unset
  
  ; 读取文件头和区服标识符
  CusFileObj := FileOpen(selectedFileURL, "r", "UTF-8")

  cusHeadStr := ""
  loop 8 {
    cusHeadStr .= String(CusFileObj.ReadChar())
  }
  if (cusHeadStr != CusHeadNum2Str) {
    MsgBox "读取失败：文件类型不匹配", "提示"
    update()
    return
  }

  ; 匹配对应的标识符
  RegionBeforeList.Choose(0) ; 重置选项
  CusFileObj.Pos := 8 ; 设定指针偏移
  cusMarkStr := CusFileObj.Read(3) ; 获取标识符字串
  for i, regionStr in Region {
    if InStr(regionStr, cusMarkStr) {
      RegionBeforeList.Choose(i)
      IsFileReady := true
      update()
      break
    }
  }

  if (!IsFileReady) {
    MsgBox "读取失败：暂不支持的区服", "提示"
  }
}

/* 保存文件 */
SaveCusFile(*) {
  global
  lockControl() ; 锁定控件
  ; 弹出文件选择，获得文件保存路径
  newFileURL := FileSelect(
    "s24", CusFileText.Value, "选择保存位置", "捏脸数据 (*.cus)"
  )
  if (newFileURL = "") {
    unlockControl()
    return
  }
  ; 如果不覆盖源文件，则复制一份
  if (newFileURL != CusFileText.Value) {
    try {
      ;FileDelete(newFileURL)
      FileCopy(CusFileText.Value, newFileURL, true)
    }
    catch as err {
      MsgBox ("文件操作异常！" . "`n`nError " Err.Extra ": " Err.Message, "Error")
      unlockControl()
    }
  }
  newFileObj := FileOpen(newFileURL, "rw")
  newMarkStr := SubStr(RegionAfterList.Text, 2, 3)
  newFileObj.Pos := 8
  loop 3 {
    str := SubStr(newMarkStr, A_Index, 1)
    newFileObj.WriteChar(Ord(str)) ; 将字符拆分后转换为数字写入文件
  }
  newFileObj.Close()
  MsgBox("保存成功！")
  unlockControl()
}

/* 锁定控件 */
lockControl() {
  ConvertBtn.Enabled := false
  CusFileBtn.Enabled := false
  RegionAfterList.Enabled := false
}

/* 解锁控件 */
unlockControl() {
  CusFileBtn.Enabled := true
  RegionAfterList.Enabled := true
  update()
}

/* 全局状态同步 */
update() {
  global
  CusFileText.Enabled := IsFileReady
  
  ;RegionBeforeList.Visible := IsFileReady
  ;RegionAfterList.Visible := IsFileReady

  ;ConvertBtn.Visible := IsFileReady
  ConvertBtn.Enabled := IsFileReady

  ;MsgBox("update()`n")
}
