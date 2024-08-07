/* 定义全局参数 */
Version := "1.6" ; 版本号
GUIWidth := 428 ; 窗体宽度
GUIHeight := 268 ; 窗体高度
Region := [" CHN - 国服", " JPN - 日服", " KOR - 韩服", " RUS - 俄服", " TWN - 台服", " USA - Steam"] ; 服务器区域字串数组
RegionRegKey := ["命运方舟", "", "", "", "", ""] ; 各服务器在注册表中的目录名（已放弃支持其他区服功能）
ClassStr := Map()
ClassStr["file"] := ["Warrior", "Fighter", "Hunter", "Magician", "Specialist", "Delain", "Warrior_Female", "Hunter_Female", "Fighter_Male"] ; 
ClassStr["CHN"] := [" 战士（男）", " 格斗（女）", " 射手（男）", " 魔法师", " 术师", " 潜伏者", "战士（女）", "射手（女）", "格斗（男）"] ; 
ClassIndex := 0
IsFileReady := false ; 是否已选取合法cus文件
IsDirReady := false ; 是否已选取目录
    
/* 窗体定义 开始 */
MyGui := Gui(, "命运方舟捏脸数据导入工具 - v" . Version)
MyGui.SetFont("s11")
MyGui.OnEvent("Close", MyGuiClose) ; 关闭窗体时清理临时文件
InnerWidth := GUIWidth - MyGui.MarginX * 2 ; 窗体内部的可用宽度

; 文件选取区域 
MyGui.AddGroupBox("Section xm y18 h82 w" InnerWidth , "步骤一：选择捏脸数据文件")
CusFileText := MyGui.AddEdit(
  "ReadOnly -tabstop r1 xs+8 ys+22 w" InnerWidth - 16 - 80 - 6, ""
)
CusFileBtn := MyGui.AddButton("Default x+6 yp-1 h52 w80", "选择...")
CusFileBtn.OnEvent("Click", SelectCusFileEvent)
MyGui.OnEvent("DropFiles", DropFileEvent) ; 监听拖入文件操作

CusFileTip := MyGui.AddText("xs+8 ys+53 w300 c666666", "支持文件拖拽选取功能，数据格式为 .cus")

; 数据类型显示与修改
CusRegionLabel := MyGui.AddText("c666666 xs+8 yp", "文件类别：")
CusRegionList := MyGui.AddDropDownList(
  "x+0 yp-4 w120 r" Region.Length, Region
)
CusClassList := MyGui.AddDropDownList(
  "x+3 yp w100 r" ClassStr["CHN"].Length, ClassStr["CHN"]
)

; 数据栏位区域
MyGui.AddGroupBox("Section xm ys+94 h118 w" InnerWidth, "步骤二：放入自定义栏位")
SlotBtn := Map()
loop 6 {
  xyStr := (A_Index = 1) ? "xs+8 ys+22" : "x+6 yp"
  SlotBtn[A_Index] := MyGui.AddButton(
    "Default Disabled w59 h59 " xyStr, 
    "栏位" A_Index - 1
  )
  SlotBtn[A_Index].OnEvent("Click", SoltBtnClick)
}

; 附加选项与功能
MyGui.SetFont("c666666")
DirStateTip := MyGui.AddText("right xs+8 y+14 w249", "如栏位不可用，请手动处理 =>")
DirRegionList := MyGui.AddDropDownList("Hidden Choose1 x+0 yp-4 w5", Region)  ; 已放弃区服选择功能，但此控价需保留
DirOpenBtn := MyGui.AddButton("Default w125 h23 x+5 yp-1", "打开数据文件夹")
DirOpenBtn.OnEvent("Click", OpenSelectDir)
; 目录位置
CusDirText := MyGui.AddEdit(
  "ReadOnly -tabstop r1 xs+8 ys+22 w100 Hidden", ""
)

; 底部信息
MyGui.SetFont("s10 c888888")
MyGui.AddLink(
  "right xs ym+" (GUIHeight - 26) " w" InnerWidth, 
  '本工具由B站UP主<a href="https://space.bilibili.com/18422589">@喵闪闪嗷呜一声</a>定制，' .
  '如需帮助请访问<a href="https://gitee.com/meowshanshan/lostark-cus-tool">项目Git仓库</a>'
)

; 显示窗体
MyGui.Show("w" . GUIWidth . " h" . GUIHeight)
CusFileBtn.Focus()
LocateCusDir(true) ; 定位捏脸数据文件目录
UpdateState()

/* 窗体定义 结束 */


/* 全局状态同步 */
UpdateState(*) {
  global
  ; 文件选取
  CusFileText.Enabled := IsFileReady
  CusFileTip.Visible := !IsFileReady
  CusRegionLabel.Visible := IsFileReady

  CusRegionList.Visible := IsFileReady
  CusRegionList.Enabled := false ; ExpCheckBox.Value
  CusClassList.Visible := IsFileReady
  CusClassList.Enabled := false ; ExpCheckBox.Value
  
  ; 文件放置
  DirOpenBtn.Enabled := IsDirReady
  DirRegionList.Enabled := false ; ExpCheckBox.Value
}

/* 栏位按钮点击事件 */
SoltBtnClick(obj, info) {
  slotIndex := Number(SubStr(obj.Text, -1)) ; 从按钮文本中截取末尾数字做index
  PutCusFile(slotIndex)
  UpdateSlotState()
}

/* 文件拖放事件 */
DropFileEvent(guiObj, guiCtrlObj, fileArray, x, y) {
  global
  if (CusFileBtn.Enabled) {
    CheckCusFile(fileArray[1])
    dir := LocateCusDir(true)
    UpdateSlotState()
  }
  UpdateState()
}

/* 选取文件事件 */
SelectCusFileEvent(*) {
  ; 弹出文件选取框
  selectedFileURL := FileSelect(
    1, , "选择捏脸数据文件", "捏脸数据 (*.cus)"
  )
  CheckCusFile(selectedFileURL)
  ; 高级模式未开启时，自动选取目录
  dir := LocateCusDir(true)
  UpdateSlotState()
  UpdateState()
}

/* 处理选取的文件 */
CheckCusFile(selectedFileURL := "") {
  global

  IsFileReady := false
  CusFileText.Value := ""
  ClassIndex := 0
  if (selectedFileURL = "") { 
    return
  } 

  cusFileObj := false
  try {
    cusFileObj := FileOpen(selectedFileURL, "r", "UTF-8")
    ; 识别区服标识符
    cusFileObj.Pos := 8 ; 设定指针偏移
    cusMarkStr := cusFileObj.Read(3) ; 获取标识符字串
    isCusMarkOK := false
    for i, regionStr in Region {
      if InStr(regionStr, cusMarkStr) {
        CusRegionList.Choose(i) ; 自动填充区服选项
        isCusMarkOK := true
        break
      }
    }
    if (!isCusMarkOK) {
      throw Error("不支持的区服")
    }
  }
  catch Error as err {
    MsgBox err.Message, "文件读取失败"
  }
  else {
    ; 显示文件路径
    CusFileText.Value := selectedFileURL
    ; 显示文件职业分类
    fileName := RegExReplace(selectedFileURL, "(.*)\\")
    className := RegExReplace(fileName, "i)Customizing_") ; 掐头
    className := RegExReplace(className, "i)_slot(.*)") ; 去尾
    
    for i, str in ClassStr["file"] {
      if (str = className) {
        ClassIndex := i
        break
      }
    }
    CusClassList.Choose(ClassIndex) ; 自动填充职业选项
    ; 临时处理，给出职业识别失败提示
    if (ClassIndex = 0) {
      MsgBox("职业类型识别失败`n（目前是通过文件名识别职业）", "提示") 
    }
    else {
      IsFileReady := true
    }
    ; 临时处理，提示数据转换
    if (CusRegionList.Text != " CHN - 国服") {
      MsgBox("已选择的文件是外服数据，国服无法使用，将为您转换为国服数据后导入。`n注意：部分外服数据使用了国服没有的参数，转换后仍然可能导入失败！", "提示")
    }
  }
  finally {
    ;updateState() ; 更新控件状态
    if(cusFileObj) {
      cusFileObj.Close() ; 关闭文件
    }
  }
  
}

/* 打开选定的目录 */
OpenSelectDir(*) {
  if (CusDirText.Value and DirExist(CusDirText.Value)) {
    Run "explore " CusDirText.Value
  }
  else {
    MsgBox "目录不存在", "提示"
  }
}

/* 定位安装目录 */
LocateCusDir(isAutoCreate := false) {
  global
  ; 初始化
  CusDirText.Value := "" 
  IsDirReady := false

  sysKeyArr := [
    "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\windows\CurrentVersion\Uninstall"
  ]
  ; 通过注册表定位根目录
  rootDir := ""
  for i, sysKey in sysKeyArr {
    key := sysKey "\" RegionRegKey[DirRegionList.Value] ; 拼接注册表路径
    rootDir := RegRead(key, "InstallSource", "")
    if (rootDir) {
      break
    }
  }
  if (!DirExist(rootDir)) {
    MsgBox("找不到游戏目录：`n" rootDir, "提示")
    return
  }
  if (!DirExist(rootDir "\EFGame")) {
    MsgBox("找不到游戏目录：`n" rootDir "\EFGame", "提示")
    return
  }
  ; 确保捏脸文件目录
  if (!DirExist(rootDir "\EFGame\Customizing")) {
    if (!isAutoCreate) {
      ; 此处需弹出询问，不同意直接return
    }
    try {
      DirCreate(rootDir "\EFGame\Customizing")
    }
    catch Error as err {
      MsgBox("捏脸文件目录创建失败！`n" rootDir "\EFGame\Customizing", "提示")
      return
    }
  }
  ; 记录目录位置
  CusDirText.Value := rootDir "\EFGame\Customizing"
  IsDirReady := true
}

/* 检测栏位可用性 */
UpdateSlotState(*) {
  global
  ; 检测前置条件
  if (!IsDirReady or !IsFileReady) {
    loop 6 {
      SlotBtn[A_Index].Enabled := false
    }
    return
  }
  ; 检测栏位
  loop 6 {
    path := CusDirText.Value "\Customizing_" ClassStr["file"][ClassIndex] "_slot" A_Index - 1 ".cus"
    SlotBtn[A_Index].Enabled := FileExist(path) ? false : true
    ;MsgBox(path " : " SlotBtn[A_Index].Enable)
  }
  
}

/* 放入捏脸数据 */
PutCusFile(slotIndex) {
  global
  newFilePath := CusDirText.Value "\Customizing_" ClassStr["file"][ClassIndex] "_slot" slotIndex ".cus"
  try {
    FileCopy(CusFileText.Value, newFilePath, true)
    ; 如果不是目标区服数据，则进行标识符转换
    if (CusRegionList.Value != DirRegionList.Value) {
      newFileObj := FileOpen(newFilePath, "rw")
      newMarkStr := SubStr(DirRegionList.Text, 2, 3)
      newFileObj.Pos := 8
      loop 3 {
        str := SubStr(newMarkStr, A_Index, 1)
        newFileObj.WriteChar(Ord(str)) ; 将字符拆分后转换为数字写入文件
      }
      newFileObj.Close()
    }
  }
  catch as err {
    MsgBox ("文件操作异常！" . "`n`nError " Err.Extra ": " Err.Message, "Error")
  }
  MsgBox("导入成功！`n请进入游戏捏脸界面，选择对应栏位并点击读取", "提示")
}

/* 窗体关闭时的操作 */
MyGuiClose(*) {
  global
  
}
