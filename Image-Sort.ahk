#SingleInstance,Force
DetectHiddenWindows,On
global v:=[],DirList:=new XML("dirlist"),settings:=new XML("settings","lib\Settings.xml"),MainTree,MainWin,wb,compare,ctrl,abbr,spo,DupCompare:=new XML("Duplicates")
v.loading:=1,ctrl:=new EasyCtrl(),v.sub:=10,Defaults(),Gui(),v.EditingControllerInput:=0
abbr:={a:"A",b:"B",back:"Bk",down:"D",left:"L",right:"R",up:"U",LeftShoulder:"LS",LThumbY_Down:"L/D",LThumbX_Left:"L/L",LeftThumb:"LB",LThumbX_Right:"L/R",LThumbY_Up:"L/U",LTrigger:"LT",RightShoulder:"RS",RThumbY_Down:"R/D",RThumbX_Left:"R/L",RightThumb:"RB",RThumbX_Right:"R/R",RThumbY_Up:"R/U",RTrigger:"RT",start:"ST",x:"X",y:"Y"}
/*
	mainwin.xml.Transform()
	m(mainwin.xml[])
*/
return
Action(key,Keyboard:=0,Alt:=0){
	tab:=Tab(),top:=Keyboard?settings.ssn("//Keyboard"):settings.ssn("//Controller")
	if(keyboard)
		node:=settings.Find(top,"descendant::Global/descendant::*/@node()",key,0)
	if(!keyboard)
		node:=settings.Find(top,"descendant::Global/" (alt?"Alt":"Main") "/descendant::*/@node()",key,0)
	/*
		;if(node:=settings.Find(top,"descendant::Global/descendant::*/@node()",key,0)){
	*/
	if(node){
		function:=ssn(node,"..").NodeName
		if(IsFunc(function))
			%function%(node.NodeName)
		return
	}
	if(v.mode>1){
		if(tab=1){
			/*
				this needs the alt treatment too
			*/
			node:=settings.Find(top,"descendant::*/@node()",key,0)
			if(v.DuplicateAction&&node.NodeName="Select"){
				ea:=cxml.CurrentEA()
				if(ea.delete)
					ActionList.Delete(cxml.xml.SSN("//*/@delete").text)
				if(ea.rename){
					ea:=cxml.xml.ea("//*[@rename]"),file:=ea.rename
					SplitPath,file,,dir,,,drive
					ActionList.Undo.under(ActionList.Undo.ssn("//*"),"file",{old:ea.file,new:ea.Rename,drive:drive,file:ea.rename})
					FileMove,% ea.file,% ea.Rename
				}
				rem:=DupCompare.SSN("//compare"),rem.ParentNode.RemoveChild(rem)
				if(DupCompare.SSN("//compare"))
					return Compare("Duplicates")
				v.DuplicateAction:=0,cxml.BuildList()
				return
			}else if(v.DuplicateAction)
				return m("Please select one of these 2")
			if((node:=MoveList.Get(key))&&Keyboard)
				return MoveList.SetCurrent(node)
			if(node:=settings.Find(top,(Keyboard?"":alt?"descendant::Alt/":"descendant::Main/") "descendant::Move/@node()",key,0)){
				if(InStr(node.NodeName,"Cycle_Move_List"))
					return MoveList.CycleList(node.NodeName)
				if(node:=MoveList.XML.sn("//list/*").item[SubStr(node.NodeName,0)-1+MoveList.next])
					return MoveList.SetCurrent(node)
	}}}
	if(node:=settings.Find(top,"descendant::Screen" tab "/" (Keyboard?"":alt?"descendant::Alt/":"descendant::Main/") "descendant::*/@node()",key,0))
		if(IsFunc(function:=ssn(node,"..").NodeName))
			return %function%(node.NodeName)
	/*
		nodes:=settings.Find(top,"descendant::*/@node()",key,1)
		while(nn:=nodes.item[A_Index-1]),action:=ssn(nn,"..").NodeName
			if(action!="move")
				return %action%(nn.NodeName)
	*/
	if(keyboard)
		Send,{%key%}
	return
}
Actions(x){
	if(x="Quick_Jump")
		return Quick_Jump()
	if(x="Properties")
		return Properties()
	if(x="Compare")
		return Compare("Selected")
	if(x="Undo")
		return Undo()
	if(x="Clear_All_Selections")
		return cxml.NoSelections()
	if(x~="Move_(All|Selected)_To_Current_Directory"){
		list:=MoveList.node.item[0].ParentNode
		if(current:=ssn(list,"*[@current]/@dir").text){
			sel:=InStr(x,"All")?cxml.xml.sn("//item"):cxml.Sel()
			while(ss:=sel.item[A_Index-1]),ea:=xml.ea(ss)
				ActionList.Move(ea.file,Trim(current,"\"))
			cxml.Highlight(),cxml.NoSelections(),cxml.SelectNext()
		}else
			m("No current move directory selected")
		return
	}
	if(x="Cycle_Mode"){
		return v.mode:=v.mode+1<=v.modemax?v.mode+1:1,MoveList.next:=0,MoveList.Update(MainTree.last)
	}if(x="Move_Selected"){
		static SubTree
		count:=cxml.Sel().length
		SubTree:=new DirTree(2,"w400 h400","",MainTree.last)
		Gui,2:Show
		return
		2GuiEscape:
		2GuiClose:
		Sleep,1
		dir:=SubTree.last
		all:=cxml.Sel()
		while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
			ActionList.Move(ea.file,SubTree.last)
		action:=m("Add:",SubTree.last,"To one of your move lists?","Yes to add to your Global list","No to add it to your currently selected Local list","btn:ync")
		if(action="yes")
			MoveList.AddDirectory(dir,1)
		if(action="no"){
			MoveList.AddDirectory(dir,0)
		}
		if(action="Cancel"){
			Gui,2:Destroy
			return cxml.Highlight()
		}
		/*
			needs a trailing \ if you add it to globals
		*/
		cxml.Highlight()
		Gui,2:Destroy
		return
	}
	if(x="Move_Mode_Off")
		return v.mode:=1,MoveList.Clear(),MoveList.Update(""),MoveList.next:=0
	if(x="Global_Move_Mode")
		return v.mode:=2,MoveList.next:=0,MoveList.Update(MainTree.last)
	if(x="Local_Move_Mode")
		return v.mode:=3,MoveList.next:=0,MoveList.Update(MainTree.last)
	Count()
	if(x="Execute_Actions")
		return ActionList.Execute()
	if(x="Clear_Selected_Actions")
		return ActionList.ClearSelected()
	if(x="Clear_All_Actions")
		return ActionList.ClearAll()
	if(IsFunc(x))
		%x%()
}
XBox(x){
	SetTimer,xbox,-1
}
AddGlobal(){
	FileSelectFolder,out,% "*" MainTree.last,3,Select a Global Directory
	if(ErrorLevel)
		return	
	if(!settings.find("//global/dir/@dir",out "\"))
		settings.add("global/dir",{dir:out "\",name:StrSplit(Trim(out,"\"),"\").pop()},,1)
	PopulateGlobal()
	return
}
EditGlobalHotkey(key:=""){
	static lastnode
	if(!IsObject(key)){
		lastnode:=settings.Find("//global/dir/@dir",ctrl.GetText("global","",3))
		return new EditHotkey("EditGlobalHotkey",lastnode)
	}lastnode.SetAttribute("hotkey",key.1)
	return PopulateGlobal(),Hotkeys()
}
AddList(ByRef list){
	/*
		if(!IsObject(list)){
			list:=[],list.push("Start Listening","Stop Listening","Commands","Move","Select")
			return list
		}list.push("Start Listening","Stop Listening","Switch To Global","Switch To Local","Commands","Move","Select")
	*/
	v.list:=[]
	if(v.mode>2){
		all:=settings.sn("//global/dir/@dir")
		while(aa:=all.item[A_Index-1])
			list.push("Global " StrSplit(Trim(aa.text,"\"),"\").pop())
	}
	for a,b in list
		v.list[b]:=1
	return list
}
AddAllSubs(){
	Default("SysListView322"),parent:=MoveList.node.item[0].ParentNode,next:=LV_GetNext()
	if(parent.NodeName="local")
		top:=parent
	else
		if(!top:=settings.Find("//locals/local/@dir",MainTree.last))
			top:=settings.Add("locals/local",{dir:MainTree.last},,1)
	Loop,Files,% dir:=ssn(top,"@dir").text "*.*",D
		if(!settings.Find(top,"dir/@dir",A_LoopFileLongPath "\"))
			new:=settings.Under(top,"dir",{dir:A_LoopFileFullPath "\",hotkey:hotkey,name:StrSplit(Trim(A_LoopFileLongPath,"\"),"\").pop()}),MoveList.Hotkey(new,top,A_LoopFileFullPath),added.=A_LoopFileFullPath "`n"
	if(!added)
		m("Nothing New Added to this current directory:",MainTree.last,"time:1")
	else
		m("Added:",added,"time:3")
	MoveList.Update(dir),MoveList.SetStatus(),PopulateLocal(),LV_Modify(next,"Select Vis Focus")
}
AddLocal(){
	static
	Gui,AddLocal:Destroy
	AL:=new DirTree("AddLocal","w800 h800",,MainTree.last)
	Gui,AddLocal:Add,Button,gAddAndContinue Default,Add And &Continue (Escape to add and close)
	local:=MoveList.node.item[0].ParentNode
	if(local.NodeName!="local")
		if(!local:=settings.Find("//locals/local/@dir",MainTree.last))
			local:=settings.Add("locals/local",{dir:MainTree.last},,1)
	Gui,AddLocal:Show,,% "Add Local Directory to " ssn(local,"@dir").text
	return
	AddLocalGuiEscape:
	AddAndContinue:
	Sleep,2
	if(!settings.Find(local,"descendant::*/@dir",AL.last))
		new:=settings.Under(local,"dir",{dir:AL.last,name:StrSplit(Trim(AL.last,"\"),"\").pop()}),MoveList.Hotkey(new,local,AL.last),MoveList.Update(ssn(local,"@dir").text),MoveList.SetStatus(),PopulateLocal(),LV_Modify(0,"-Select"),LV_Modify(sn(new,"preceding-sibling::*").length+1,"Select Vis Focus")
	if(A_ThisLabel="AddAndContinue")
		return
	AddLocalGuiClose:
	Gui,AddLocal:Destroy
	return
}
QuickNewLocal(){
	/*
		make this into the quick jump but give it the ability to create and then auto-add it
		not for actual quick jump and make it available for both Global and 3-4 locals
	*/
	InputBox,NewLocal,Add A New Local Directory,% "This Will Add a Local Directory to " MainTree.last "`n`nOnly the name of the directory, no \ / or multiple directories"
	if(ErrorLevel||NewLocal="")
		return
	if(NewLocal~="\\|\/")
		return
	if(!top:=settings.Find("//locals/local/@dir",MainTree.last))
		top:=settings.add("locals/local",{dir:MainTree.last})
	if(!settings.find(top,"@dir",MainTree.last NewLocal)){
		FileCreateDir,% MainTree.last NewLocal
		new:=settings.Under(top,"dir",{dir:MainTree.last NewLocal,name:NewLocal})
	}PopulateLocal(),LV_Modify(sn(new,"preceding-sibling::*").length,"Select Vis Focus")
	/*
		InputBox,dir,Enter the name of the new directory,Just the name without sub-directories or anything
		if(ErrorLevel||dir~="\\|\/")
			return
		NewDir:=MainTree.last dir
		local:=Local()
		if(!settings.Find(local,"descendant::*/@dir",NewDir)){
			new:=settings.Under(local,"dir",{dir:NewDir}),MoveList.Hotkey(new,local,NewDir)
			if(!FileExist(NewDir))
				FileCreateDir,%NewDir%
		}
		MoveList.Update(NewDir),MoveList.SetStatus(),PopulateLocal(),LV_Modify(0,"-Select"),LV_Modify(sn(new,"preceding-sibling::*").length+1,"Select Vis Focus")
	*/
}
EditLocalHotkey(key:=""){
	static lastnode
	if(!IsObject(key)){
		Default("SysListView322")
		if(LV_GetNext())
			return new EditHotkey("EditLocalHotkey",(lastnode:=v.mode!=4?ssn(settings.Find("//locals/local/@dir",MainTree.last),"*[" LV_GetNext() "]"):lastnode:=MoveList.node.item[LV_GetNext()-1]))
		return
	}dup:=sn(lastnode.ParentNode,"descendant::*[@hotkey='" key.1 "']"),lastnode.SetAttribute("hotkey",key.1),PopulateLocal(),Hotkeys()
	while(dd:=dup.item[A_Index-1]),ea:=xml.ea(dd)
		if(ea.dir!=ssn(lastnode,"@dir").text)
			MoveList.Hotkey(dd,dd.ParentNode,ea.dir)
	MoveList.Update(ssn(lastnode.ParentNode,"@dir").text),MoveList.SetStatus(),PopulateLocal(),LV_Modify(0,"-Select"),LV_Modify(sn(lastnode,"preceding-sibling::*").length+1,"Select Vis Focus")
}
AutoAction(set:=1){
	if(set)
		v.Auto_Action:=MainWin[].AutoAction,settings.Add("Options",{Auto_Action:v.Auto_Action})
	GuiControl,,% MainWin.xml.ssn("//tab[@tab='5']/control[@track='AutoAction']/@hwnd").text,% v.Auto_Action
}Auto_Action(){
	v.Auto_Action:=v.Auto_Action?0:1,AutoAction(0),settings.Add("Options",{Auto_Action:v.Auto_Action})
}
Calc(list,sub){
	v.x:=Ceil(Sqrt(list.length)),v.y:=Round(Sqrt(list.length)),mww:=MainWin.width,mwh:=MainWin.height,ww:=Floor((mww/v.x)-sub),hh:=Floor(((mwh-MainWin.Status)/v.y)-sub)
	info:={ww:ww,hh:hh,sub:sub,ax:(mww-(ww*v.x+(sub*v.x))),ay:(mwh-(hh*v.y+(sub*v.y)+MainWin.Status)),yadd:(v.x*(v.y-1))}
	return info
}
class ActionList{
	static xml:=new XML("ActionList"),undo:=new XML("undo")
	Move(file,dir){
		node:=this.Get(file,1),MoveFile:=ssn(node,"@file").text
		SplitPath,MoveFile,,MoveDir
		if(dir=MoveDir)
			return m("You are attempting to move the same file to itself")
		node.SetAttribute("move",dir)
		if(v.Auto_Action)
			this.Execute()
	}Delete(file){
		SplitPath,file,filename,dir,ext,nne,drive
		if(!FileExist(drive "\Deleted Images"))
			FileCreateDir,%drive%\Deleted Images
		node:=this.Get(file,1),node.SetAttribute("Delete",1),node.SetAttribute("new",Unique(drive "\Deleted Images\" filename))
		if(v.Auto_Action)
			this.Execute()
	}Delete_Forever(file){
		node:=this.Get(file,1),node.SetAttribute("DeleteForever",1)
		if(v.Auto_Action)
			this.Execute()
	}Get(file,clear:=0){
		if(!node:=this.xml.Find("//@file",file)){
			if(!clear)
				return
			node:=this.xml.add("action",{file:file},,1)
		}
		if(clear){
			all:=sn(node,"@*")
			while(aa:=all.item[A_Index-1])
				if(aa.NodeName!="file")
					node.RemoveAttribute(aa.NodeName)
		}
		return node
	}Execute(){
		all:=this.xml.sn("//action"),top:=this.Undo.under(this.Undo.ssn("//*"),"action",{time:A_Now}),sure:="",surelist:=[],rem:=DupCompare.SSN("//list"),rem.ParentNode.RemoveChild(rem),DupList:=DupCompare.Add("list")
		onum:=num:=DirList.Find("//@file",cxml.Current("file"),"preceding-sibling::*").length+1
		while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
			file:=ea.file
			SplitPath,file,filename,dir,ext,nne,drive
			if(ea.move){
				if(!FileExist(ea.move))
					FileCreateDir,% ea.move
				if(FileExist(ea.move "\" filename)){
					DupCompare.Under(DupList,"compare",{new:ea.file,current:ea.move "\" filename})
					Continue
				}else if(DirList.Find("//@file",ea.file,"preceding-sibling::*").length<onum){
					num--
					FileMove,% ea.file,% rename:=Unique(ea.move "\" filename)
				}
			}
			if(ea.delete){
				if(DirList.Find("//@file",ea.file,"preceding-sibling::*").length<onum)
					num--
				if(!this.Undo.ssn("//drives/drive[text()='" drive "']"))
					this.Undo.add("drives/drive",,drive,1)
				FileMove,% ea.file,% rename:=Unique(ea.new)
				rem:=DirList.Find("//@file",ea.file),rem.ParentNode.RemoveChild(rem)
			}
			if(ea.deleteforever){
				sure.=ea.file "`n",surelist.push(ea.file)
			}
			if(!ea.deleteforever){
				rem:=DirList.Find("//@file",ea.file),rem.ParentNode.RemoveChild(rem)
				this.Undo.under(top,"file",{old:ea.file,new:rename,drive:drive,file:rename})
			}
		}
		if(sure){
			if(m("btn:ync","def:2","You are about to completely remove:",(SubStr(sure,1,200) (StrLen(sure)>200?"...":"")),"This CAN NOT be undone.  Continue?")!="YES")
				return m("GOOD!")
			for a,b in surelist{
				if(DirList.Find("//@file",b,"preceding-sibling::*").length<onum)
					num--
				FileDelete,%b%
				rem:=DirList.Find("//@file",ea.file),rem.ParentNode.RemoveChild(rem)
		}}
		if(DupCompare.SN("//compare").length)
			return Compare("Duplicates")
		if(!top.FirstChild)
			top.ParentNode.RemoveChild(top)
		while(node:=this.xml.ssn("//action"))
			node.ParentNode.RemoveChild(node)
		cxml.BuildList(DirList.ssn("//list/item[" Round(num>=0?num:0) "]"))
		if(v.mode=4)
			v.mode:=v.lastmode,Count()
		cxml.NoSelections()
	}ClearSelected(){
		sel:=cxml.Sel()
		while(ss:=sel.item[A_Index-1]),ea:=xml.ea(ss)
			rem:=this.xml.Find("//action/@file",ea.file),rem.ParentNode.RemoveChild(rem)
		cxml.Highlight()
	}ClearAll(){
		while(rem:=this.xml.ssn("//action"))
			rem.ParentNode.RemoveChild(rem)
		cxml.Highlight()
	}
}
Class cxml{
	static xml:=new XML("cxml"),move:=new XML("move"),delete:=new XML("delete"),deleteforever:=new XML("deleteforever")
	ClearList(){
		rem:=this.xml.ssn("//list"),rem.ParentNode.RemoveChild(rem)
		return this.xml.under(this.xml.ssn("//*"),"list")
	}NoSelections(){
		rem:=this.xml.ssn("//selected"),rem.ParentNode.RemoveChild(rem),this.Highlight()
	}Sel(){
		return this.xml.ssn("//selected/item")?this.xml.sn("//selected/*"):this.xml.sn("//list/*[@tv='" this.Current("tv") "']")
	}SelectNext(){
		if(v.showimage){
			node:=DirList.ssn("//*[@tv='" cxml.Current("tv") "']")
			next:=node.NextSibling?node.NextSibling:node.ParentNode.FirstChild
			cxml.BuildList(next)
		}else{
			onum:=num:=this.xml.Find("//@file",cxml.Current("file"),"preceding-sibling::*").length+1
			num:=num+1>wb.images.length?1:num+1
			cxml.SetCurrent(cxml.xml.ssn("//list/item[" num "]"))
			cxml.Highlight()
		}
	}List(){
		return v.showimage?this.xml.sn("//*[@current]"):this.xml.sn("//list/*")
	}Fill(first:=""){
		count:=v.showimage?1:MainWin[].count,top:=this.xml.ssn("//list"),this.selected:=first,sub:=Mod(current:=Number(first),count),first:=DirList.ssn("//list/item[" current-sub+1 "]")
		if(DirList.sn("//list/*").length=0)
			return
		while,(this.xml.sn("//list/*").length<count){
			ea:=xml.ea(first)
			if(A_Index=1)
				looped:=ea.file
			else if(ea.file=looped)
				break
			if(!this.xml.find("//list/*/@file",ea.file))
				top.AppendChild(first.CloneNode(1))
			first:=first.NextSibling?first.NextSibling:first.ParentNode.FirstChild
	}}BuildList(next:=""){
		top:=cxml.ClearList(),this.Fill(next),this.SetCurrent(next),Display(),this.Highlight(),this.Last()
	}CurrentEA(){
		return xml.ea(this.Current())
	}Current(x:=""){
		return x?this.xml.ssn("//list/item[@current]/@" x).text:this.xml.ssn("//list/item[@current]")
	}SetCurrent(node:=""){
		this.NoCurrent()
		node.xml?(this.xml.find("//list/item/@file",ssn(node,"@file").text).SetAttribute("current","yes")):(this.xml.ssn("//list/item").SetAttribute("current","yes"))
	}NoCurrent(){
		all:=this.xml.sn("//descendant::item[@current]")
		while,aa:=all.item[A_Index-1]
			aa.RemoveAttribute("current")
	}Highlight(){
		ctrl.Disable("IE")
		if(!this.xml.ssn("//list/*[@current]"))
			this.xml.ssn("//list/*").SetAttribute("current","yes")
		all:=wb.images
		while,aa:=all.item[A_Index-1],ea:=xml.ea(node:=this.xml.find("//list/item/@file",aa.id)){
			selected:=this.xml.find("//selected/item/@file",aa.id)?1:0
			aa.ParentNode.style.bordercolor:=(ea.current&&selected?"#00ff00":ea.current&&!selected?"#ffff00":!ea.current&&!selected?"#aaaaaa":"#ff00ff")
			if(node:=ActionList.Get(aa.id)){
				ea:=xml.ea(node)
				if(ea.delete)
					ImageText(aa.id,"Delete",0xFF00FF)
				else if(ea.deleteforever)
					ImageText(aa.id,"Delete Forever",0xAACC00)
				else if(ea.move)
					ImageText(aa.id,"Move To: " ea.move,0x00FF00)
			}else
				ImageText(aa.id,"No Actions",0xAAAAAA)
			if(DirList.Find("//@file",aa.id,"preceding-sibling::*").length=0){
				aa.ParentNode.GetElementsByTagName("P").item[0].style.backgroundcolor:="#AAAAAA"
				aa.ParentNode.GetElementsByTagName("SPAN").item[1].style.color:="#11ff11"
			}
		}ctrl.Enable("IE"),Count()
	}Last(){
		if((file:=SplitPath(this.Current("file")).file)&&DirList.Find("//@file",this.Current("file"),"preceding-sibling::*").length){
			if(!last:=settings.Find("//last/dir/@dir",MainTree.last))
				last:=settings.Add("last/dir",{dir:MainTree.last},,1)
			last.SetAttribute("file",file)
		}else if(rem:=settings.Find("//last/dir/@dir",MainTree.last))
			rem.ParentNode.RemoveChild(rem)
	}Select(x:=0){
		if(IsObject(compare)){
			ea:=this.CurrentEA()
			if(ea.delete)
				Undo.Action("Delete",this.Current(),1)
			else{
				rename:=ea.rename
				SplitPath,rename,rename,dir
				this.current().SetAttribute("filename",rename)
				Undo.Action("Move",this.Current(),1)
			}
			Compare("Duplicates")
			return
		}parent:=this.xml.add("selected")
		if(node:=cxml.xml.find("//selected/descendant::*/@file",this.Current("file")))
			node.ParentNode.RemoveChild(node)
		else
			parent.AppendChild(this.Current().CloneNode(1))
		this.Highlight()
	}m(){
		m(this.xml[],this.move[],this.delete[],this.deleteforever[])
	}
}
class DirSelect{
	__New(Win,Title,NewButton:=0){
		static nw
		nw:=new GUIKeep(win),this.dir:=new DirTree(win,"x0 y0 w400 h450",nw,MainTree.last,"wh"),this.obj:=nw,this.win:=win
		nw.Add("Edit,w400 vnewdir," MainTree.last ",wy")
		nw.Add("Button,gaddnewdir,Add Directory,y")
		GuiControl,%win%:Show,% this.dir.hwnd
		nw.Show(Title)
		this.updateHWND:=nw.xml.SSN("//*[@type='Edit']/@hwnd").text
		v.returnlast:=this
		return this
		addnewdir:
		m(nw[].newdir)
		return
	}Close(){
		this.obj.CloseWin()
		Gui,% this.win ":Destroy"
	}return(last){
		GuiControl,% this.win ":",% this.updateHWND,%last%
		/*
			t(this.win,this.updateHWND)
		*/
		/*
			for a,b in this
				list.=a "=" b "`n"
			m(list)
		*/
		/*
			GuiControl,
		*/
	}
}
Class DirTree{
	static obj:=[]
	__New(win,pos,parent:="",start:="",track:="h"){
		static
		if(!this.xml)
			this.xml:=new XML("cache","lib\cache.xml")
		if(parent)
			info:=parent.Add("TreeView," pos " gDirTree.Notify AltSubmit,," track ",2"),hwnd:=info.hwnd
		else
			Gui,%win%:Add,TreeView,%pos% hwndhwnd gDirTree.Notify AltSubmit
		GuiControl,%win%:+v%hwnd%,%hwnd%
		DirTree.obj[hwnd]:=this,this.win:=win,this.hwnd:=hwnd,this.ext:=settings.ssn("//extensions").text,this.ext:=this.ext?this.ext:"gif,jpg,jpeg,png,bmp"
		DriveGet,List,List
		for a,b in StrSplit(list)
			this.Cache(b ":\")
		if(start&&FileExist(start))
			this.Build(start)
		if(win)
			this.Populate()
		GuiControl,%win%:+gDirTree.Notify,%hwnd%
		return this
	}Build(dir){
		if(!dir)
			return
		dir:=Trim(dir,"\")
		for a,b in StrSplit(dir,"\"){
			build.=b "\"
			if(last:=this.xml.Find("//@dir",build)){
				keep:=last
				if(del:=ssn(keep,"@wait").text)
					keep.RemoveAttribute("sub"),TV_Delete(del),this.Default(),keep.RemoveAttribute("wait")
			}else{
				Loop,Files,%buildlast%*.*,D
				{
					new:=this.xml.Under(keep,"dir",{dir:A_LoopFileLongPath "\"})
					Loop,Files,%A_LoopFileLongPath%\*.*,D
					{
						new.SetAttribute("sub",1)
						Break
				}}keep:=this.xml.find("//@dir",build)
			}buildlast:=build
		}this.Populate(1),Default("SysTreeView321",this.win),TV_Modify(ssn(this.xml.Find("//@dir",build),"@tv").text,"Select Vis Focus")
	}Notify(a,b*){
		Critical
		static lastthis
		if(a="k")
			return
		this:=DirTree.obj[A_GuiControl],ea:=xml.ea((node:=this.xml.ssn("//*[@tv='" b.1 "']")))
		if(ea.dir)
			this.last:=ea.dir
		if(v.returnlast)
			v.returnlast.return(this.last)
		if(v.startup)
			return
		if((a="+")&&ea.wait){
			Sleep,0
			this.Disable(1),this.Default(),TV_Delete(ea.wait),this.Cache(ea.dir),this.Populate(1),this.Disable(),node.RemoveAttribute("wait")
		}if(this.hwnd!=MainTree.hwnd)
			return
		if(a="s"){
			lastthis:=this
			v.break:=1
			SetTimer,NotifyRefresh,-450
			return
			NotifyRefresh:
			this:=lastthis
			while(v.looping){
				Sleep,300
			}ctrl.Disable("DirTree"),ctrl.NoRedraw("DirTree"),rem:=DirList.ssn("//list"),rem.ParentNode.RemoveChild(rem),top:=DirList.Under(DirList.ssn("//*"),"list"),Default("SysTreeView322"),TV_Delete(),obj:=[],v.break:=0,v.looping:=1
			for a,b in StrSplit(this.ext,","){
				Loop,Files,% this.last "*." b,F
				{
					if(!obj[b])
						obj[b]:=TV_Add(b)
					DirList.Under(top,"item",{file:A_LoopFileLongPath,dir:A_LoopFileDir,ext:A_LoopFileExt,tv:ctrl.Add("DirTree","",A_LoopFileName,obj[b])})
					if(v.break)
						Break 2
				}if(!TV_GetChild(root))
					TV_Delete(root)
			}MoveList.Update(this.last),v.looping:=0,v.Break:=0,ctrl.Enable("DirTree"),ctrl.Redraw("DirTree")
			SetTimer,bl,-300
			return
			refresh:
			this.Refresh()
			bl:
			ea:=xml.ea(settings.find("//dir/@dir",this.last))
			cxml.BuildList(DirList.find("//@file",ea.dir ea.file))
			return
	}}Cache(dir,refresh:=0,display:=0){
		tick:=A_TickCount,xx:=this.xml,node:=xx.find("//@dir",dir)
		if(!node||refresh||ssn(node,"@sub").text){
			if(refresh)
				this.Refresh(),this.Populate()
			top:=xx.find("//@dir",dir),node.RemoveAttribute("sub")
			if(!top)
				top:=xx.under(xx.ssn("//*"),"dir",{dir:dir})
			Loop,Files,%dir%*.*,D
			{
				if(!next:=xx.find("//@dir",A_LoopFileLongPath "\"))
					next:=xx.under(top,"dir",{dir:A_LoopFileLongPath "\"})
				Loop,Files,%A_LoopFileLongPath%\*.*,D
				{
					next.SetAttribute("sub",1)
					Break
		}}}if(refresh=2)
			return
	}Refresh(){
		SplashTextOn,,50,Indexing, Please Wait...
		all:=this.xml.sn("//*[@dir]"),dir:=SubStr(this.last,1,InStr(this.last,"\",0,0,2)),parent:=this.xml.Find("//@dir",dir)
		Loop,Files,%dir%*.*,D
		{
			if(!next:=this.xml.Find("//@dir",A_LoopFileLongPath "\")){
				next:=this.xml.Under(parent,"dir",{dir:A_LoopFileLongPath "\"})
				Loop,Files,%A_LoopFileLongPath%\*.*,D
				{
					next.SetAttribute("sub",1)
					Break
				}
			}else{
				Loop,Files,% ssn(next,"@dir").text "*.*",D
				{
					if(!next.HasChildNodes())
						next.SetAttribute("sub",1),next.SetAttribute("wait",TV_Add("Please Wait...",ssn(next,"@tv").text))
					Break
		}}}top:=this.xml.Find("//@dir",dir,"descendant::*"),rem:=[]
		while(tt:=top.item[A_Index-1]),ea:=xml.ea(tt)
			if(!FileExist(ea.dir))
				TV_Delete(ea.tv),rem.push(tt)
		for a,b in rem
			b.ParentNode.RemoveChild(b)
		this.Populate(1)
		SplashTextOff
	}Populate(expand:=0){
		static xx
		this.Default()
		xx:=this.xml,this.Disable(1)
		not:=xx.sn("//dir[not(@tv)]")
		while,aa:=not.item[A_Index-1],ea:=xml.ea(aa){
			aa.SetAttribute("tv",tv:=TV_Add(StrSplit(Trim(ea.dir,"\"),"\").pop(),ssn(aa.ParentNode,"@tv").text,"Sort"))
			if(ea.sub)
				aa.SetAttribute("wait",TV_Add("Please Wait...",tv))
		}
		if(node:=xx.ssn("//*[@last]"))
			TV_Modify(ssn(node,"@tv").text,"Select Vis Focus Expand"),node.RemoveAttribute("last")
		if(last:=xx.sn("//*[@last]"))
			while,ll:=last.item[A_Index-1]
				ll.RemoveAttribute("last")
		this.Disable(0),this.local()
	}Disable(x:=0){
		static last:=[]
		last.x:=x,last.this:=this
		if(x)
			GuiControl,% this.win ":-Redraw",% this.hwnd
		else
			GuiControl,% this.win ":+Redraw",% this.hwnd
		return
	}
	Local(){
		local:=this.xml.sn("//*[@local]")
		while,ll:=local.item[A_Index-1]
			ll.RemoveAttribute("local")
		all:=settings.sn("//locals/local/@dir")
		while,aa:=all.item[A_Index-1],ea:=xml.ea(aa)
			this.xml.find("//@dir",aa.text).SetAttribute("local",1)
	}Default(){
		Gui,% this.win ":Default"
		Gui,% this.win ":TreeView",% this.hwnd
	}
}
class EasyCTRL{
	Register(type,name,hwnd,label,win){
		this.Control[name]:={type:type,hwnd:hwnd,label:label,win:win,name:name}
	}Disable(Control){
		obj:=this.Control[Control]
		GuiControl,% obj.win ":+g",% obj.hwnd
	}Enable(Control){
		obj:=this.Control[Control]
		GuiControl,% obj.win ":+g" obj.label,% obj.hwnd
	}NoRedraw(Control){
		obj:=this.Control[Control]
		GuiControl,% obj.win ":-Redraw",% obj.hwnd
	}Redraw(Control){
		obj:=this.Control[Control]
		GuiControl,% obj.win ":+Redraw",% obj.hwnd
	}AutoHDR(Control,count:=1){
		this.Default(this.Control[Control])
		Loop,%count%
			LV_ModifyCol(A_Index,"AutoHDR")
	}GetTV(Control){
		obj:=this.Control[Control],this.Default(obj)
		return TV_GetSelection()
	}GetText(Control,next:="",column:=1){
		obj:=this.Control[Control],this.Default(obj)
		if(obj.type="TreeView")
			TV_GetText(text,x.3?x.3:TV_GetSelection())
		if(obj.type="ListView"&&(next||LV_GetNext()))
			LV_GetText(text,next?next:LV_GetNext(),column)
		return text
	}Add(Control,options,info*){
		obj:=this.Control[Control],this.Default(obj)
		if(obj.type="ListView")
			return LV_Add(options,info*)
		if(obj.type="TreeView"){
			return TV_Add(info.1,info.2,options)
		}
	}Default(obj){
		if(!obj.win)
			return
		Gui,% obj.win ":Default"
		Gui,% obj.win ":" obj.type,% obj.hwnd
}}
Class GUIKeep{
	static keep:=[]
	__New(win){
		Gui,%win%:Destroy
		Gui,%win%:+hwndhwnd
		Gui,%win%:Margin,0,0
		this.hwnd:=hwnd,this.id:="ahk_id" hwnd,this.win:=win,this.xml:=new XML("gui"),GUIKeep.keep[win]:=this
		Gui,%win%:+LabelGuiKeep.
		for a,b in {border:DllCall("GetSystemMetrics",int,32),caption:DllCall("GetSystemMetrics",int,4),menu:DllCall("GetSystemMetrics",int,15)}
			this[a]:=b
	}Exit(){
		for a,b in ["tv","wait"]{
			all:=MainTree.xml.sn("//*[@" b "]")
			while(aa:=all.item[A_Index-1])
				aa.RemoveAttribute(b)
		}
		last:=settings.add("last",{dir:MainTree.last}),settings.add("showimage",,v.showimage),pos:=settings.add("gui")
		for a,b in {tab:Tab(),mode:v.mode=4?v.LastMode:v.mode}
			last.SetAttribute(a,b)
		last:=settings.Add("hotkeys")
		for a,b in {global:ctrl.GetText("Global"),local:ctrl.GetText("Local")}
			last.SetAttribute(a,b)
		noblank:=settings.sn("//locals/local")
		while(nn:=noblank.item[A_Index-1])
			if(!nn.HasChildNodes())
				nn.ParentNode.RemoveChild(nn)
		this.CloseWin(),MainTree.xml.save(1)
		if(settings.ssn("//last/@dir"))
			settings.Save(1)
		else
			m(settings[])
		for a,b in spo
			ObjRelease(spo[a])
		ExitApp
		return
	}__Get(){
		return this.Add(1)
	}Handle(Gui,Type){
		if(IsLabel(Gui Type)||IsFunc(Gui Type)){
			SetTimer,% Gui Type,-1
			return 1
		}
		return 0
	}Escape(){
		this:=GUIKeep.keep[A_Gui]
		if(!this.Handle(A_Gui,"Escape"))
			this.exit()
	}Close(){
		this:=GUIKeep.keep[A_Gui]
		if(!this.Handle(A_Gui,"Close"))
			this.Exit()
	}Size(a,b,c){
		this:=GUIKeep.keep[A_Gui]
		if(a!=1){
			all:=this.xml.sn("//*[@track!='']"),pos:=this.WinPos(),this.width:=pos.w,this.height:=pos.h
			while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa),npos:=""{
				for a,b in StrSplit(ea.track){
					if(b="x"){
						if(val:=pos.w+ea.ox){
							npos.=" x" val
						}
					}
					if(b="y"){
						if(val:=pos.h+ea.oy)
							npos.=" y" val
					}
					if(b="w"){
						if(val:=pos.w+ea.ow)
							npos.=" w" val
					}
					if(b="h"){
						if(val:=pos.h+ea.oh)
							npos.=" h" val
					}
				}if(npos)
					GuiControl,% this.win ":" (ea.type~="ActiveX|TreeView"?"Move":"MoveDraw"),% ea.hwnd,%npos%
				if(ea.type="ActiveX"){
					images:=wb.images,calc:=Calc(images,10)
					while(im:=images.item[A_Index-1])
						aw:=!Mod(A_Index,v.x)?calc.ww+calc.ax:calc.ww,ah:=A_Index>calc.yadd?calc.hh+calc.ay:calc.hh,im.ParentNode.style.width:=aw,im.ParentNode.style.height:=ah,im.style.maxwidth:=aw,im.style.maxheight:=ah,im.ParentNode.GetElementsByTagName("p").item[0].style.width:=aw-calc.sub
				}
			}this.SetParts()
	}}Add(x*){
		static
		if(x.1=1){
			Gui,% this.win ":Submit",Nohide
			all:=this.xml.sn("//*[@var]"),vars:=[]
			while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa),var:=ea.var
				vars[var]:=%var%
			return vars
		}
		for a,b in x{
			info:=StrSplit(b,",")
			if(info.5)
				Gui,% this.win ":Tab",% info.5
			Gui,% this.win ":Add",% info.1,% info.2 " hwndhwnd", % info.3
			if(info.4||info.5){
				if(!tab:=this.xml.ssn("//tab[@tab='" info.5 "']"))
					tab:=this.xml.add("tab",{tab:info.5},,1)
				control:=this.xml.under(tab,"control",{hwnd:hwnd+0,track:info.4}),control.SetAttribute("type",info.1),Control.SetAttribute("name",info.6)
			}if(info.1="StatusBar")
				Control.SetAttribute("StatusBar",1)
			if(RegExMatch(info.2,"\bv(\w+)",var))
				Control.SetAttribute("var",var1)
			RegExMatch(info.2,"\bg(\w+)",label)
			if(info.6)
				Ctrl.Register(info.1,info.6,hwnd,label1,this.win)
			Gui,% this.win ":Tab"
		}return xml.ea(Control)
	}Show(title=""){
		static show:=[]
		if(this.xml.ssn("//*[@track]"))
			Gui,% this.win ":+Resize"
		Gui,% this.Win ":Show",AutoSize Hide
		this.Compile(),ea:=xml.EA(settings.ssn("//gui/win[@name='" this.win "']"))
		if(ea.max){
			show.push(this.id),max:=1
			SetTimer,max,-100
		}
		pos:=ea.size?ea.size:"AutoSize"
		Gui,% this.Win ":Show",% max?"Hide " pos:pos,%title%
		return
		max:
		while(id:=show.pop())
			WinMaximize,%ID%
		return
	}SetParts(){
		w:=[],pos:=this.WinPos()
		Loop,9
			w.push(pos.w/9)
		SB_SetParts(w*)
	}Compile(){
		all:=this.xml.sn("//control"),pos:=this.WinPos(),status:=this.xml.ssn("//*[@StatusBar]/@hwnd").text
		if(status){
			ControlGetPos,,,,h,,ahk_id%status%
			this.status:=h
		}
		while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
			ControlGetPos,x,y,w,h,,% "ahk_id" ea.hwnd
			x-=this.Border,y-=this.Border+this.Caption
			for a,b in StrSplit(ea.track){
				if(b="x")
					aa.SetAttribute("ox",x-pos.w)
				if(b="y")
					aa.SetAttribute("oy",y-pos.h)
				if(b="w")
					aa.SetAttribute("ow",w-pos.w)
				if(b="h")
					aa.SetAttribute("oh",h-pos.h)
			}
		}
	}AddHWND(hwnd,track:="",tab:=""){
		if(track){
			if(!node:=this.xml.ssn("//tab[@tab='" tab "']"))
				node:=this.xml.add("tab",{tab:tab},,1)
			this.xml.under(node,"control",{hwnd:hwnd+0,track:track})
		}
	}WinPos(){
		VarSetCapacity(rect,16),DllCall("GetClientRect",ptr,this.hwnd,ptr,&rect)
		WinGetPos,x,y,,,% this.ID
		w:=NumGet(rect,8),h:=NumGet(rect,12),text:=(x!=""&&y!=""&&w!=""&&h!="")?"x" x " y" y " w" w " h" h:""
		return {x:x,y:y,w:w,h:h,text:text}
	}CloseWin(){
		if(!win:=settings.SSN("//gui/win[@name='" this.win "']"))
			win:=settings.Under(settings.Add("gui"),"win",{name:this.win})
		WinGet,mm,MinMax,% this.id
		if(mm=1)
			win.SetAttribute("max",1)
		if(mm=0)
			win.SetAttribute("size",this.WinPos().text),win.RemoveAttribute("max")
}}
class Speech{
	__New(){
		Speech.voice:=ComObjCreate("SAPI.SpInprocRecognizer"),AudioInputs:=Speech.voice.GetAudioInputs(),Speech.RuleList:=[]
		if(!AudioInputs.count)
			return
		Speech.voice.AudioInput:=AudioInputs.Item[0],Speech.AudioInputs:=AudioInputs.Count(),ObjRelease(AudioInputs),Speech.Context:=Speech.voice.CreateRecoContext(),Speech.grammar:=Speech.Context.CreateGrammar(),Speech.Rules:=Speech.grammar.Rules(),ComObjConnect(Speech.Context,Speech),Speech.null:=ComObjEnwrap(0),Speech.enabled:=Round(settings.ssn("//Options/@Voice").text),Speech.list:=[],list:=[],Speech.Display:=[],Speech.Screen[],all:=settings.SN("//Keyboard/*")
		while(aa:=all.item[A_Index-1]){
			list:=[],next:=sn(aa,"descendant::*/@*")
			while(nn:=next.item[A_Index-1])
				list.push(nn.NodeName)
			Speech.AddRule(aa.NodeName,list,InStr(aa.NodeName,"Screen")?2:1)
		}
		Speech.Rule:=Speech.Rules.Add("MoveDirectory",0x1|0x20)
		Speech.AddRule("GlobalSpeech",["Stop Listening","Close Program","Next","Back","First_Image"])
		Speech.AddRule("SwitchTo",["Global","Local"])
		Speech.AddRule("Help",["Help","Exit"])
		Speech.AddRule("Listen",["Start Listening","What Can I Say"])
		Speech.AddRule("State",["Commands","Select"])
		Speech.Numbers()
		Speech.Toggle("GlobalSpeech,SwitchTo,Help,Listen,State,Global")
		ctrls:=MainWin.xml.SN("//control"),list:=[]
		while(cc:=ctrls.item[A_Index-1]),ea:=xml.ea(cc){
			if(ea.type="Button"){
				if(!IsObject(obj:=list[(tab:=ssn(cc,"ancestor::tab/@tab").text)]))
					obj:=list[tab]:=[]
				obj.push(ea.name)
		}}for a,b in list
			Speech.AddRule("Buttons" a,b,1)
	}Recognition(StreamNumber,StreamPosition:="",RecognitionType:="",Result:="",Context:=""){
		static list,count
		text:=Result.PhraseInfo().GetText(),rule:=result.PhraseInfo().rule.name
		/*
			t(rule,text,"time:1")
		*/
		t(rule,text,"time:1")
		if(text="What Can I Say")
			return m(Speech.DisplayText,Display (Speech.commands?Speech.Display["Screen" Tab()]:""))
		if(RegExMatch(rule,"O)Buttons(\d)",found)){
			if(found.1=Tab())
				ControlClick,,% "ahk_id" MainWin.xml.ssn("//*[@name='" text "']/@hwnd").text
			return
		}
		if(text="Start Listening"&&rule="Listen"){
			return Speech.Enabled:=1,SetTitle(),settings.add("Options",{Voice:Speech.enabled})
		}
		if(rule="ULDR")
			return Selection(text)
		if(!Speech.Enabled)
			return
		if(text="Close Program"){
			MainWin.Exit()
		}
		if(text="Stop Listening")
			return Speech.Enabled:=0,SetTitle(),settings.add("Options",{Voice:Speech.enabled})
		if(rule="GlobalSpeech"){
			if(IsFunc(function:=settings.SSN("//Keyboard/descendant::*[@" text "]").NodeName))
				%function%(text)
			t(function,text)
		}
		if(text="Select")
			return cxml.Select()
		if(RegExMatch(rule,"O)Screen(\d+)",found)){
			nn:=settings.SSN("//Keyboard/Screen" found.1 "/descendant::*[@" text "]").NodeName
			if(IsFunc(nn))
				%nn%(text)
		}
		if(rule="Help"){
			if(text="Help")
				return Help()
			if(RegExMatch(text,"O)(\w+)_Screen",found)){
				Tab(text)
			}
			if(text="Exit"){
				return t(),Speech.Commands:=0,Speech.select:=0,Speech.Toggle("Global,Numbers,Help,State,GlobalSpeech,Listen,SwitchTo"),SetTitle(),Speech.ToggleScreen(0)
			}
		}
		if(rule="Global"){
			function:=settings.SSN("//Keyboard/Global/*[@" text "]").NodeName
			if(IsFunc(function))
				%function%(text)
			return
		}
		if(rule="SwitchTo"){
			v.mode:=text="global"?2:3,MoveList.Update(MainTree.last)
			return
		}
		if(rule~="Part"){
			for a,b in StrSplit(text," "){
				node:=cxml.xml.SSN("//list/item[" b "]")
				if(InStr(text," ")){
					parent:=cxml.xml.add("selected")
					if(rem:=cxml.xml.find("//selected/descendant::*/@file",ssn(node,"@file").text))
						rem.ParentNode.RemoveChild(rem)
					else
						parent.AppendChild(node.CloneNode(1))
				}else
					cxml.SetCurrent(node)
			}return cxml.Highlight()
		}
		if(text="Commands"){
			return Speech.Commands:=1,SetTitle(),Speech.Toggle("Global,Screen" Tab() ",GlobalSpeech,Help,Listen,SwitchTo"),t(Speech.DisplayText Speech.Display["Screen" Tab()]),Speech.ToggleScreen(1)
		}
		if(RegExMatch(text,"O)^Global (.*)",found))
			return MoveList.SetCurrent(settings.ssn("//global/dir[@name='" found.1 "']"),1)
		else if(rule="MoveDirectory"){
			if(move:=MoveList.xml.ssn("//*[@name='" text "']"))
				MoveList.SetCurrent(move,1)
			else if(move:=settings.ssn("//global[@name='" text "']")){
				MoveList.SetCurrent(move,1)
			}
		}
		if((node:=Speech.list[text])&&(rule="Global"||rule="Screen" Tab())&&Speech.Commands){
			function:=ssn(node,"..").NodeName
			return %function%(node.NodeName)
		}
	}Numbers(){
		static Modes:=[]
		Speech.RuleList["Numbers"]:=1
		for a,b in Modes
			b.Clear()
		Modes:=[]
		if(!mode:=Speech.Rules.FindRule("Select"))
			mode:=Speech.rules.Add("Select", 0x1|0x20)
		modes.push(mode),startstate:=mode.InitialState()
		count:=MainWin[].count
		Loop,% count?count:9
			startstate.AddWordTransition(Speech.null,A_Index)
		Loop,% count?count:9
		{
			parts:=[],index:=A_Index
			if(!part:=Speech.Rules.FindRule("Part" A_Index))
				part:=Speech.rules.add("Part" A_Index,0x1|0x20)
			modes.push(part)
			parts.0:=part.InitialState()
			Loop,% A_Index-1{
				parts[A_Index]:=part.AddState()
				parts[A_Index-1].AddRuleTransition(parts[A_Index],modes.1)
			}
			parts[parts.MaxIndex()].AddRuleTransition(Speech.null,modes.1,"",0,"",1)
		}Speech.Rules.Commit(),Speech.Grammar.CmdSetRuleState("Select",1)
		Loop,% count?count:9
			Speech.grammar.CmdSetRuleState("Part" A_Index,1)
	}AddRule(Name,list,AddList:=1){ ;33=SRATopLevel|SRADynamic
		if(AddList=1)
			Speech.RuleList[name]:=1
		if(AddList=2)
			Speech.Screen[name]:=1
		rule:=Speech.Rules.Add(name,33),main:=rule.InitialState()
		for a,b in list
			main.AddWordTransition(Speech.null,b),Speech.Display[name].=b "`n"
		Speech.rules.Commit()
	}MoveList(info){
		Speech.Rule.Clear(),state:=Speech.Rule.InitialState()
		for a,b in info{
			try state.AddWordTransition(Speech.null,b)
			catch e
				throw Exception("Could not add rule """ b """: " e.Message)
		}Speech.Rules.Commit(),Speech.grammar.DictationSetState(0),Speech.grammar.CmdSetRuleState("MoveDirectory",Speech.Enabled)
	}Toggle(x){
		Speech.DisplayText:=""
		for a,b in Speech.RuleList{
			state:=RegExMatch(x,"\b" a "\b")>0,Speech.Grammar.CmdSetRuleState(a,state)
			if(state)
				Speech.DisplayText.=speech.Display[a]
		}
	}ToggleScreen(x:=0){
		tab:=Tab()
		for a,b in Speech.Screen
			Speech.grammar.CmdSetRuleState(a,tab=A_Index&&x)
	}
}
class XBox{
	static keystroke:={22528:"A",22529:"B",22549:"Back",22545:"Down",22546:"Left",22547:"Right",22544:"Up",22533:"LeftShoulder",22561:"LThumbY_Down",22563:"LThumbX_Left",22550:"LeftThumb",22562:"LThumbX_Right",22560:"LThumbY_Up",22534:"LTrigger",22532:"RightShoulder",22577:"RThumbY_Down",22579:"RThumbX_Left",22551:"RightThumb",22578:"RThumbX_Right",22576:"RThumbY_Up",22535:"RTrigger",22548:"Start",22530:"X",22531:"Y"}
	__New(count:=0){
		static
		this.library:=DllCall("LoadLibrary","str",(A_OSVersion~="8\.|10\.")?"Xinput1_4":"Xinput1_3"),this.ctrl:=[],main:=this,VarSetCapacity(State,16),main.ctrl:=[]
		if(!this.library){
			m("Error loading the DLL")
			ExitApp
		}
		for a,b in {xGetState:"XInputGetState",xBattery:"XInputGetBatteryInformation",xSetState:"XInputSetState",xkeystroke:"XInputGetKeystroke"}
			this[a]:=DllCall("GetProcAddress","ptr",this.library,"astr",b)
		xbox.main:=this,down:=hold:=value:=[],xbox.allstates:=[],v.startxbox:=0,v.held:=[]
		goto,listen
		return
		getstate:
		ret:=DllCall(main.xkeystroke,UInt,0,UInt,0,UPtr,&State)
		if(ret=1167)
			goto,nocontroller
		button:=NumGet(state,0),st:=NumGet(state,4),key:=xbox.keystroke[button]
		if(st=1&&button)
			Press(key)
		if(st=1&&!v.held[key]&&key)
			v.held[key]:=key
		if(st=2&&v.held[key])
			v.held.Delete(key)
		if(v.held[key]~="\b(Up|Down|Left|Right)\b"&&st=5)
			Press(key)
		/*
			xbox.main.battery(0)
		*/
		return
		watch:
		ret:=DllCall(main.xGetState,int,0,"uint*",test)
		if(ret=1167)
			goto,nocontroller
		if(ret=0&&xbox.stopped=1){
			SetTimer,getstate,50
			v.nocontroller:=xbox.stopped:=0,SetTitle()
		}
		return
		nocontroller:
		v.nocontroller:=1,SetTitle()
		Hotkey,IfWinActive,% mainwin.id
		Hotkey,!R,Listen,On
		SetTimer,getstate,Off
		SetTimer,watch,Off
		xbox.stopped:=1
		return
		Listen:
		v.nocontroller:=0,SetTitle()
		Hotkey,!R,Listen,Off
		SetTimer,getstate,50
		SetTimer,watch,1000
		return
	}
	Battery(Controller){
		VarSetCapacity(batt,8),info:=DllCall(this.xBattery,"uint",Controller,"uint",0,"uptr",&batt)
		Return NumGet(batt,1)
	}
}
Class XML{
	keep:=[]
	__New(param*){
		if(!FileExist(A_ScriptDir "\lib"))
			FileCreateDir,%A_ScriptDir%\lib
		root:=param.1,file:=param.2
		file:=file?file:root ".xml"
		temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath")
		this.xml:=temp
		if(FileExist(file)){
			FileRead,info,%file%
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else
				temp.loadxml(info),this.xml:=temp
		}else
			this.xml:=this.CreateElement(temp,root)
		this.file:=file
		xml.keep[root]:=this
	}CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).parentnode
	}Add(path,att:="",text:="",dup:=0,list:=""){
		p:="/",dup1:=this.ssn("//" path)?1:0,next:=this.ssn("//" path),last:=SubStr(path,InStr(path,"/",0,0)+1)
		if(!next.xml){
			next:=this.ssn("//*")
			Loop,Parse,path,/
				last:=A_LoopField,p.="/" last,next:=this.ssn(p)?this.ssn(p):next.appendchild(this.xml.CreateElement(last))
		}
		if(dup&&dup1)
			next:=next.parentnode.appendchild(this.xml.CreateElement(last))
		for a,b in att
			next.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			next.SetAttribute(b,att[b])
		if(text!="")
			next.text:=text
		return next
	}Local(){
		node:=maintree.xml.find("//@dir",maintree.last)
		if(!ssn(node,"@local"))
			while,node:=node.ParentNode
				if(ssn(node,"@local"))
					break
		return {list:sn(node:=settings.find("//local/dir/@dir",xml.ea(node).dir),"dir/@dir"),node:node}
	}Find(info*){
		doc:=info.1.NodeName?info.1:this.xml
		if(info.1.NodeName)
			node:=info.2,find:=info.3,return:=info.4?"SelectNodes":"SelectSingleNode",search:=info.4!=1?info.4:""
		else
			node:=info.1,find:=info.2,return:=info.3?"SelectNodes":"SelectSingleNode",search:=info.3!=1?info.3:""
		if(!find||!return||!node)
			return
		if(InStr(find,"'"))
			return doc[return](node "[.=concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "')]" (search!=0&&info.4!=1&&info.3!=1?"/..":"") (search?"/" search:""))
		else{
			return doc[return](node "[.='" find "']" (search!=0&&info.4!=1&&info.3!=1?"/..":"") (search?"/" search:""))
		}
	}Key(node,find){
		return this.xml.SelectSingleNode("//Keyboard/" node "/@*[.='" find "']").NodeName
	}Controller(node,find){
		return this.xml.SelectSingleNode("//Controller/" node "/@*[.='" find "']").NodeName
	}Under(under,node:="",att:="",text:="",list:=""){
		if(node="")
			node:=under.node,att:=under.att,list:=under.list,under:=under.under
		new:=under.appendchild(this.xml.createelement(node))
		for a,b in att
			new.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			new.SetAttribute(b,att[b])
		if(text)
			new.text:=text
		return new
	}SSN(path){
		return this.xml.SelectSingleNode(path)
	}SN(path){
		return this.xml.SelectNodes(path)
	}
	__Get(x=""){
		return this.xml.xml
	}Get(Path,Default){
		text:=this.ssn(path).text
		return text?text:Default
	}Transform(){
		static
		if(!IsObject(xsl)){
			xsl:=ComObjCreate("MSXML2.DOMDocument")
			style=<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">`n<xsl:output method="xml" indent="yes" encoding="UTF-8"/>`n<xsl:template match="@*|node()">`n<xsl:copy>`n<xsl:apply-templates select="@*|node()"/>`n<xsl:for-each select="@*">`n<xsl:text></xsl:text>`n</xsl:for-each>`n</xsl:copy>`n</xsl:template>`n</xsl:stylesheet>
			xsl.loadXML(style),style:=null
		}
		this.xml.transformNodeToObject(xsl,this.xml)
	}Save(x*){
		if(x.1=1)
			this.Transform()
		filename:=this.file?this.file:x.1.1
		if(this.xml.SelectSingleNode("*").xml="")
			return m("Errors happened. Reverting to old version of the XML")
		ff:=FileOpen(filename,0),text:=ff.Read(ff.length),ff.Close()
		if(!this[])
			return m("Error saving the " this.file " xml.  Please get in touch with maestrith if this happens often")
		if(text!=this[])
			file:=FileOpen(filename,"rw"),file.seek(0),file.write(this[]),file.length(file.position)
	}EA(path,att:=""){
		list:=[]
		if(att)
			return path.NodeName?ssn(path,"@" att).text:this.ssn(path "/@" att).text
		if(nodes:=path.NodeName)
			nodes:=path.SelectNodes("@*")
		else if(!IsObject(path))
			nodes:=this.sn(path "/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.NodeName]:=n.text
		return list
	}
}
ssn(node,path){
	return node.SelectSingleNode(path)
}
sn(node,path){
	return node.SelectNodes(path)
}
Clean(Clean,tab=""){
	if(tab)
		return RegExReplace(Clean,"[^\w ]")
	Clean:=RegExReplace(RegExReplace(Clean,"&")," ","_")
	if(InStr(Clean,"`t"))
		Clean:=SubStr(Clean,1,InStr(Clean,"`t")-1)
	return Clean
}
Compare(info:=0){
	if(info="selected"){
		if(v.CompareScreen)
			return v.CompareScreen:=0,cxml.BuildList(DirList.Find("//@file",v.lastimage))
		if(cxml.xml.sn("//selected/*").length<2)
			return m("Please select at least 2 images to compare")
		v.lastimage:=cxml.Current("file"),cxml.ClearList(),list:=cxml.xml.sn("//selected/*"),top:=cxml.xml.ssn("//list")
		while,ll:=list.item[A_Index-1],ea:=xml.ea(ll)
			top.AppendChild(ll.CloneNode(1))
		Display(),cxml.SetCurrent(),cxml.Highlight(),v.CompareScreen:=1,cxml.NoSelections()
	}else if(info="Duplicates"){
		if(!DupCompare.SN("//compare").length)
			return
		cxml.ClearSel(),top:=cxml.ClearList(),ea:=xml.EA(DupCompare.SSN("//compare")),cxml.xml.Under(top,"item",{file:ea.current,delete:ea.new,current:"Yes"}),cxml.xml.Under(top,"item",{file:ea.new,rename:Unique(ea.current)}),v.showimage:=0,v.DuplicateAction:=1,Display(),cxml.SetCurrent(),cxml.Highlight(),DelRen()
	}
}
Convert_Hotkey(key){
	StringUpper,key,key
	for a,b in [{Shift:"+"},{Win:"#"},{Ctrl:"^"},{Alt:"!"}]
		for c,d in b
			key:=RegExReplace(key,"\" d,c "+")
	return key
}
Count(a*){
	if(!a.1){
		file:=cxml.Current("file"),v.count:=Round(sn((ff:=DirList.find("//@file",file)),"preceding-sibling::*").length+1) " of " DirList.sn("//item").length
		if(sel:=cxml.xml.sn("//selected/*").length)
			v.count.=" : " sel " Items Selected"
		SB_SetText(v.count (v.mode=2?": Global":v.mode="3"?": Local":v.mode=4?" :" v.parent:""),1),SetTitle()
	}else if(a.2="Normal"){
		SetTimer,UpdateImages,-500
		return
		UpdateImages:
		if(wb.images.length!=MainWin[].count&&DirList.sn("//list/*").length)
			ea:=cxml.xml.ea("//list/item[1]"),cxml.ClearList(),cxml.Populate(ea.file),Display(),cxml.Highlight()
		return
}}
Default(Control:="SysTreeView321",win:=1){
	type:=InStr(Control,"SysTreeView32")?"TreeView":"ListView"
	Gui,%win%:Default
	Gui,%win%:%type%,%control%
}
Defaults(){
	Global:={Screen:["Next_Screen","Previous_Screen","Help"],Movement:["Left","Right","Up","Down","Next_Control","Previous_Control"],Delete:["Delete"],XBox:["Activate_XBox_Controller"]}
	Screen1:={Actions:["Auto_Action","Auto_Action","Clear_All_Actions","Clear_All_Selections","Clear_Selected_Actions","Compare","Cycle_Mode","Execute_Actions","Fix_Image","Global_Move_Mode","Local_Move_Mode","Move_All_To_Current_Directory","Move_Mode_Off","Move_Selected","Move_Selected_To_Current_Directory","Properties","Quick_Jump","Toggle_Voice_Commands","Top_Level","Top_Level","Undo"]
		    ,Navigation:["Back","Forward","First_Image"]
		    ,Selection:["Next","Select","Select_All","Toggle_FullScreen"]}
	Screen2:={Navigation:["Refresh_Directory_List"]}
	Screen3:={ReOrder:["Move_Directory_Up","Move_Directory_Down"]}
	Move:={Move:["Cycle_Move_List_Forward","Cycle_Move_List_Back","Directory_1","Directory_2","Directory_3","Directory_4","Directory_5","Directory_6","Directory_7","Directory_8"]}
	Keyboard:={Back:"^Left",Clear_All_Actions:"+^Enter",Clear_All_Selections:"^!Space",Clear_Selected_Actions:"+Enter",Compare:"!Enter",Cycle_Mode:"``",Cycle_Move_List_Forward:"+F1",Delete:"Delete",Directory_1:"q",Directory_2:"w",Directory_3:"e",Directory_4:"r",Directory_5:"a",Directory_6:"s",Directory_7:"d",Directory_8:"f",Down:"Down",Execute_Actions:"^!Enter",Forward:"^Right",Global_Move_Mode:2,Left:"Left",Local_Move_Mode:3,Move_All_To_Current_Directory:"!a",Move_Selected_To_Current_Directory:"+!a",Move_Directory_Down:"^Down",Move_Directory_Up:"^Up",Move_Mode_Off:1,Move_Selected:"!m",Next:"Enter",Next_Screen:"!Right",Previous_Screen:"!Left",Properties:"!p",Right:"Right",Select:"Space",Select_All:"^a",Toggle_FullScreen:"^Enter",Top:"^Up",Undo:"^z",Up:"Up",Previous_Control:"+Tab",Next_Control:"Tab",Activate_XBox_Controller:"!r",Help:"F1",Toggle_Voice_Commands:"^v"}
	ControllerMain:={Compare:"LThumbY_Down",Directory_4:"LThumbY_Up",Global_Move_Mode:"RightShoulder",Cycle_Move_List_Forward:"RTrigger",Cycle_Move_List_Back:"LTrigger",Delete:"B",Directory_1:"LThumbX_Left",Directory_2:"LThumbY_Down",Directory_3:"LThumbX_Right",Directory_5:"RThumbX_Left",Directory_6:"RThumbY_Down",Directory_7:"RThumbX_Right",Directory_8:"RThumbY_Up",Down:"Down",Left:"Left",Move_Directory_Down:"RThumbY_Down",Move_Directory_Up:"RThumbY_Up",Move_Mode_Off:"",Next:"A",Next_Screen:"Start",Previous_Screen:"Back",Properties:"LeftThumb",Right:"Right",Select:"X",Select_All:"Y",Toggle_FullScreen:"RightThumb",Up:"Up",Alt:"LeftShoulder",Previous_Control:"RThumbX_Left",Next_Control:"RThumbX_Right"}
	ControllerAlt:={Move_Mode_Off:"RightShoulder"}
	;"A","B","Back","Down","Left","Right","Up","LeftShoulder","LThumbY_Down","LThumbX_Left","LeftThumb","LThumbX_Right","LThumbY_Up","LTrigger","RightShoulder","RThumbY_Down","RThumbX_Left","RightThumb","RThumbX_Right","RThumbY_Up","RTrigger","Start","X","Y"
	HotkeyObj:={Global:global,Move:Move,Screen1:Screen1,Screen2:Screen2,Screen3:Screen3}
	if(!root:=settings.ssn("//Keyboard"))
		root:=settings.Add("Keyboard")
	for a,b in HotkeyObj{
		if(!node:=ssn(root,a))
			node:=settings.Under(root,a)
		for c,d in b{
			if(!next:=ssn(node,c))
				next:=settings.Under(node,c)
			for e,f in d{
				if(!ssn(next,"@" f))
					next.SetAttribute(f,Keyboard[f])
	}}}
	if(!root:=settings.ssn("//Controller"))
		root:=settings.Add("Controller")
	for a,b in HotkeyObj{
		if(!main:=ssn(root,a))
			main:=settings.Under(root,a)
		for e,f in ["Main","Alt"]{
			obj:="Controller" f
			if(!node:=ssn(main,f))
				node:=settings.Under(main,f)
			for c,d in b{
				if(!next:=ssn(node,c))
					next:=settings.Under(node,c)
				for e,f in d{
					if(!ssn(next,"@" f))
						next.SetAttribute(f,%obj%[f])
	}}}}
	if(!settings.SSN("//Controller/Global/Main/Alt"))
		settings.Add("Controller/Global/Main/Alt",{Alt:ControllerMain.Alt})
	all:=settings.sn("//global/dir")
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
		if(!ea.name)
			aa.SetAttribute("name",StrSplit(Trim(ea.dir,"\"),"\").pop())
}
Delete(action:=""){
	Delete:
	tab:=Tab()
	if(key:=v.EditingControllerInput){
		;m(main:=ctrl.GetText("HotkeysLV"),v.EditingControllerInput)
		node:=settings.SSN("//Controller/" ctrl.GetText("HotkeysTV") "/" (key="A"?"Main":"Alt") "/*/@" ctrl.GetText("HotkeysLV")).text:=""
		SetTimer,PopKeys,-1
		v.EditingControllerInput:=0
		SplashTextOff
		return
	}
	if(tab=2){
		dir:=MainTree.last
		Loop,Files,%dir%*.*,DFR
		{
			list.=A_LoopFileFullPath "`n"
			if(StrLen(list)>500){
				list.="And More...."
				break
			}
		}
		if(!list){
			node:=MainTree.xml.Find("//@dir",dir)
			next:=node.nextSibling?node.nextSibling:node.previousSibling
			next:=next?next:next.ParentNode
			FileRemoveDir,%dir%
			MainTree.Refresh()
			Default("SysTreeView321"),TV_Modify(ssn(next,"@tv").text)
		}
	}
	if(tab=3){
		ControlGetFocus,Focus,% MainWin.ID
		Default(Focus),next:=LV_GetNext(),node:=MoveList.node.item[0].ParentNode,nodename:=node.NodeName,directory:=ssn(node,"@dir").text
		directory:=directory?directory:MainTree.last
		if(!next)
			return
		remove:=[],item:=0
		while(item:=LV_GetNext(item))
			LV_GetText(dir,item,3),remove.push(dir)
		if((Focus="SysListView322"&&NodeName="local")||(Focus="SysListView321"&&NodeName="global")){
			for a,b in remove
				rem:=settings.Find((nodename="global")?settings.ssn("//settings/global"):settings.Find("//locals/local/@dir",directory),"descendant::*/@dir",b),rem.ParentNode.RemoveChild(rem)
			{
				(Focus="SysListView321")?PopulateGlobal():PopulateLocal()
				dir:=ssn(MoveList.node.item[0].ParentNode,"@dir").text
				MoveList.Update(dir)
				LV_Modify(next>LV_GetCount()?LV_GetCount():next,"Select Vis Focus")
				MoveList.SetStatus()
				return
			}
		}
		if(Focus="SysListView321"){
			for a,b in Remove
				rem:=settings.Find(settings.ssn("//settings/global"),"descendant::*/@dir",b),rem.ParentNode.RemoveChild(rem)
			return v.mode:=2,MoveList.Update(),MoveList.SetStatus(),PopulateGlobal(),LV_Modify(next>LV_GetCount()?LV_GetCount():next,"Select Vis Focus")
		}
		if(Focus="SysListView322"){
			for a,b in remove
				rem:=settings.Find(settings.Find("//locals/local/@dir",directory),"descendant::*/@dir",b),rem.ParentNode.RemoveChild(rem)
			return v.mode:=3,MoveList.Update(MainTree.last),MoveList.SetStatus(),PopulateLocal()
		}
	}
	if(tab=4){
		Default("SysListView323") ;,LV_GetText(item,LV_GetNext())
		/*
			for a,b in ["keyboard","controller"]
				if(node:=settings.ssn("//" b "/@" item))
					settings.ssn("//" b).RemoveAttribute(item)
		*/
		m(v.ListView[LV_GetNext()].xml)
		return PopulateHotkeys()
	}if(tab=1){
		sel:=cxml.Sel()
		while(ss:=sel.item[A_Index-1]),ea:=xml.ea(ss)
			ActionList[action](ea.file)
		cxml.SelectNext(),cxml.NoSelections()
}}
DelRen(){
	divs:=wb.GetElementsByTagName("div")
	for a,b in [") To Delete This Duplicate",") To Rename It"]
		(item:=divs.item[A_Index].GetElementsByTagName("p").item[0]).innerhtml:="Select This (Press " settings.ssn("//Keyboard/Screen1/Selection/@Select").text " or " settings.ssn("//Controller/Screen1/descendant::*/@Select").text " On Your Controller" b,item.style.color:="red",item.style.fontsize:="30px"
}
Display(){
	list:=cxml.List(),rem:=wb.GetElementsByTagName("div").item[0],rem.ParentNode.RemoveChild(rem),top:=wb.CreateElement("div")
	if(!list.length)
		return Count()
	GuiControl,1:-Redraw,AtlAxWin1
	calc:=Calc(list,10)
	while,ll:=list.item[A_Index-1],ea:=xml.ea(ll){
		div:=wb.CreateElement("div"),style:=div.style,span:=wb.CreateElement("span"),sp:=span.style,img1:=wb.CreateElement("img"),im:=img1.style,img1.src:=ea.file,img1.id:=ea.file
		aw:=!Mod(A_Index,v.x)?calc.ww+calc.ax:calc.ww,ah:=A_Index>calc.yadd?calc.hh+calc.ay:calc.hh
		for a,b in {width:aw,height:ah,display:"table-cell",textalign:"center",verticalalign:"middle",display:"block",position:"Relative",float:"Left",border:Floor(calc.sub/2)"px solid black"}
			if(b)
				Style[a]:=b
		for a,b in {display:"inline-block",height:"100%",verticalalign:"middle"}
			sp[a]:=b
		for a,b in {maxwidth:aw,maxheight:ah,verticalalign:"middle"}
			im[a]:=b
		tt:=wb.CreateElement("p"),ss:=wb.CreateElement("span"),text:=tt.style
		;,filter:"alpha(opacity=60)"
		for a,b in {border:"3px solid black",position:"absolute",textposition:"center",width:aw-calc.sub "px",bottom:"0px",left:"0px",textalign:"center",backgroundcolor:"black",color:"Grey"}
			Text[a]:=b
		cnode:=DirList.find("//*/@file",ea.file),stext:=(!cnode.PreviousSibling&&!cnode.NextSibling?"< Testing >":!cnode.PreviousSibling?"< Testing":!cnode.NextSibling?"Testing >":"Testing"),ss.innerhtml:=stext
		for a,b in [[tt,ss],[span,tt],[div,span],[div,img1],[div,tt],[top,wb.body.AppendChild(div)],[wb.body,top]]
			(b.1).AppendChild(b.2)
		/*
			style.backgroundcolor:=!node.PreviousSibling?"#FFFFFF":!node.NextSibling?"#AAAAAA":"#000000"
			COLOR THE TEXT BACKGROUND FOR FIRST/LAST
		*/
	}wb.GetElementsByTagName("div").item[0].style.overflow:="auto"
	Sleep,% list.length*15
	if(Tab()=1&&!v.helptab)
		GuiControl,1:+Redraw,AtlAxWin1
}
EditControllerAction(key){
	static bindings:={A:"Main Binding",B:"Alt Binding"}
	if(v.EditingControllerInput!=0){
		main:=ctrl.GetText("HotkeysTV"),type:=StrSplit(bindings[v.EditingControllerInput]," ").1,Default("SysListView323"),obj:=v.ListView[LV_GetNext()]
		if(!top:=settings.ssn("//Controller/" main))
			top:=settings.Add("Controller/" main)
		if(!next:=ssn(top,type))
			next:=settings.Under(top,type)
		if(!further:=ssn(next,obj.NodeName))
			further:=settings.Under(next,obj.NodeName)
		rem:=settings.Find(next,"descendant::*/@node()",key,1)
		while(rr:=rem.item[A_Index-1])
			rr.text:=""
		if(further.nodename="Alt"&&InStr(key,"trigger"))
			return m("Sorry but due to issues with the triggers they can not be set to the alternate key.","This is an issue that Microsoft has that I have told them about")
		further.SetAttribute(obj.node.NodeName,key)
		v.EditingControllerInput:=0
		SetTimer,popkeys,-1
		SplashTextOff
	}else{
		v.EditingControllerInput:=key
		SplashTextOn,320,150,Press any input,% "Press any input to set the " bindings[v.EditingControllerInput] " for " main:=ctrl.GetText("HotkeysLV") "`n`nPress Escape to Exit`n`nPress Delete to Remove"
	}
}
EditKeyboardHotkey(x=""){
	static lastnode
	if(!IsObject(x))
		return Default("SysListView323"),lastnode:=v.listview[LV_GetNext()].node,new EditHotkey(A_ThisFunc,lastnode)
	lastnode.text:=x.1
	SetTimer,PopKeys,-1
	for a,b in xml.ea(ssn(lastnode,".."))
		Try{
			Hotkey,%b%,Hotkey,On
		}
	if(lastnode.xml~="Activate_XBox")
		SetTitle()
}
Escape(){
	if(v.EditingControllerInput){
		v.EditingControllerInput:=0
		SplashTextOff
	}
}
Execute_Actions(){
	ActionList.Execute()
	return
}
Fix_Image(){
	im:=wb.images
	fix:=[]
	num:=DirList.Find("//@file",cxml.Current("file"),"preceding-sibling::*").length+1
	while,ii:=im.item[A_Index-1]
		if(ii.width=28&&ii.height=30){
			text:=ii.ParentNode.GetElementsByTagName("span").item[1]
			text.innerhtml:="Testing!!!!!!",text.style.color:="Red"
			fix.push(ii.id)
			/*
				ii.ParentNode.RemoveChild(ii)
			*/
			rem:=DirList.Find("//@file",ii.id),rem.ParentNode.RemoveChild(rem)
		}
	file:=MainTree.last
	SplitPath,file,,,,,drive
	if(!FileExist(drive "\Fixed Images"))
		FileCreateDir,%drive%\Fixed Images
	dir:=drive "\Fixed Images",wia:=ComObjCreate("WIA.ImageFile")
	Sleep,200
	for a,file in fix{
		SplitPath,file,filename,,ext,nne
		wia.loadfile(file),ip:=ComObjCreate("WIA.ImageProcess"),ip.filters.add(IP.FilterInfos("Convert").FilterID),IP.Filters(1).Properties("FormatID").Value := ext!="png"?"{B96B3CAF-0728-11D3-9D7B-0000F81EF32E}":"{B96B3CAE-0728-11D3-9D7B-0000F81EF32E}"
		wia.savefile(dup:=Unique(dir "\" nne (ext!="png"?".png":".jpg")))
		if(newlist.MaxIndex()<count)
			newlist.push(dup)
		if(FileExist(dup))
			FileDelete,%file%
	}cxml.BuildList(DirList.ssn("//list/item[" Round(num>=0?num:0) "]"))
}
FormatTime(time,Format="M/dd/yyyy h:mm:sstt"){
	FormatTime,time,%time%,%format%
	return time
}
Gui(){
	v.startup:=1,tabs:="1|2|3|4|5",v.tabmax:=StrSplit(tabs,"|").MaxIndex()
	MainWin:=new GUIKeep(1)
	Gui,-DPIScale
	v.Screens:=5,new Speech()
	MainWin.Add("StatusBar,,Testing :),,1","Tab,x-100 y-100 w0 h0," tabs)
	MainTree:=new DirTree(1,"x0 y0 w400 h450",MainWin)
	MainWin.Add("ActiveX,x0 y0 w800 h523 vWB,mshtml:,wh,1,IE","TreeView,x400 y0 w400 h450,,wh,2,DirTree","ListView,x0 y0 w400 h450 glasthotkey NoSortHdr AltSubmit,Name|Hotkey|Full Path,h,3,GlobalMoveDirectories","ListView,x400 y0 w400 h450 glasthotkey NoSortHdr AltSubmit,Name|Hotkey|Full Path,wh,3,LocalMoveDirectories","Button,xm y450 gAddGlobal,Add &Global Directory,y,3,Add_Global_Directory","Button,x+M gEditGlobalHotkey,Edit Global &Hotkey,y,3,Edit_Global_Hotkey","Button,x+M gAddLocal,Add &Local Directory,y,3,Add_Local_Directory","Button,x+M gQuickNewLocal,&Quick New Local,y,3,Quick_New_Local","Button,x+M gAddAllSubs,Add All Local &Sub-Directories,y,3,Add_All_Local_Sub-Directories","Button,x+M gEditLocalHotkey,Edit Local H&otkey,y,3,Edit_Local_Hotkey"
			,"TreeView,x0 y0 w200 h450 gPopKeys,,h,4,HotkeysTV","ListView,x200 y0 w600 h450 -Multi gHotkeyLV NoSortHdr AltSubmit,Action|Keyboard|Controller Main Binding (Press A to Change)|Controller Alt Binding (Press B to Change),wh,4,HotkeysLV","Button,xm y450 gEditKeyboardHotkey Default,Edit &Keyboard Hotkey,y,4,Edit_Keyboard_Hotkey"
			,"DropDownList,x0 y0 vcount gSetCount,1|2|4|6|9||12|16|20,,5","Checkbox,gTopLevel vTopLevel,Top Level,TopLevel,5","Checkbox,gAutoAction vAutoAction,Auto Action,AutoAction,5")
	last:=settings.ssn("//last/@dir").text,v.startup:=0,v.ModeMax:=3,v.mode:=settings.Get("//last/@mode",1),v.showimage:=settings.ssn("//showimage").text
	Sleep,500
	Default("SysTreeView321"),PopulateGlobal(),TV_Modify(ssn(MainTree.xml.Find("//@dir",last,0),"../@tv").text,"Select Vis Focus"),Hotkeys(),MainWin.Show("Image Sort"),PopulateHotkeys(1),PopulateLocal()
	GuiControl,1:Choose,SysTabControl321,% settings.get("//last/@tab",1)
	wb.write("<!DOCTYPE html><html><body leftmargin=0 topmargin=0 rightmargin=0 bottommargin=0></body><div></div></html>"),wb.body.style.backgroundcolor:=0
	if(settings.ssn("//Options/@XBox").text)
		new XBox()
	for a,b in {TopLevel:"Top_Level",AutoAction:"Auto_Action"}{
		if(v[b]:=settings.ssn("//Options/@" b).text)
			%a%(0)
	}
	SetTimer,lastmode,-300
	return
	lastmode:
	v.loading:=0
	MoveList.Current(MainTree.last)
	return
	1Escape:
	return
}
+Escape::
MainWin.Exit()
return
^F1::
if(m("Reset All Controls?","btn:ync")="Yes"){
	for a,b in [settings.SSN("//Keyboard"),settings.SSN("//Controller")]
		b.ParentNode.RemoveChild(b)
	settings.Save(1)
	Reload
}
/*
	cxml.xml.Transform()
	m(cxml.xml[])
*/
return
Hotkeys(){
	Hotkey,IfWinActive,% MainWin.ID
	Hotkey,Tab,Next_Control,On
	Hotkey,+Tab,Previous_Control,On
	Hotkey,Esc,Escape,On
	/*
		Hotkey,Delete,Delete,On
	*/
	Hotkey,RButton,RButton,On
	Hotkey,F5,TreeRefresh,On
	/*
		clear out all hotkeys not set by the xml so that "hopefully" when any hotkey comes back it'll be the right case
	*/
	/*
		Hotkey,!r,xbox,On
	*/
	all:=settings.sn("//Keyboard/descendant::*")
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
		for a,b in ea
			Try
				Hotkey,%b%,Hotkey,On
	}all:=settings.sn("//global/descendant::*/@hotkey|//locals/descendant::*/@hotkey")
	while(aa:=all.item[A_Index-1]){
		Try
			Hotkey,% aa.text,Hotkey,On
	}
	return
	xbox:
	new XBox(),settings.Add("Options",{XBox:1})
	return
	TreeRefresh:
	MainTree.Refresh()
	return
	hotkey:
	Action(A_ThisHotkey,1)
	return
}
ImageText(image,text,color:=""){
	TextNode:=wb.GetElementById(image).ParentNode.GetElementsByTagName("span").item[1]
	TextNode.InnerText:=text
	if(color!="")
		TextNode.style.color:=color
}
LastHotkey(){
	if(A_GuiEvent!="I")
		return
	if(global:=ctrl.GetText("Global"))
		settings.Add("settings/global").SetAttribute("last",Global)
	if(local:=ctrl.GetText("Local"))
		node:=v.mode=4?MoveList.node.item[0].ParentNode:settings.Find("//locals/local/@dir",MainTree.last),node.SetAttribute("last",local)
}
Local(){
	local:=MoveList.node.item[0].ParentNode
	if(local.NodeName!="local"){
		if(!local:=settings.Find("//locals/local/@dir",MainTree.last))
			local:=settings.Add("locals/local",{dir:MainTree.last},,1)
	}
	return local
}
Move(action:=""){
	;Future use?
}
Class MoveList{
	static next:=0,xml:=new XML("movelist")
	Current(dir){
		this.Current:=dir,this.Update(dir),this.SetStatus()
	}Get(key){
		return this.xml.ssn("//*[@hotkey='" key "']")
	}CycleList(direction){
		add:=v.mode=4&&next=0?7:8
		RegExMatch(direction,"Cycle_Move_List_(.*)",found)
		this.Clear()
		length:=this.xml.sn("//dir").length
		this.next:=found1="Forward"?(this.next+add>length?0:this.next+add):(this.next-add>=0?this.next-add:(Floor(length/add)*add))
		this.SetStatus()
	}Clear(){
		Loop,8
			SB_SetText("",A_Index+1)
		return Count()
	}Update(dir:=""){
		if(v.loading)
			return
		if(v.mode=4){
			if(!dir)
				v.mode:=2,Count(),m("dir?",dir,"why?")
			else
				if(node:=settings.Find("//locals/local/@dir",dir))
					this.node:=sn(node,"*")
		}
		if(v.mode=3){
			if(MainTree.xml.find("//@dir",dir,"@local").length)
				this.node:=sn(settings.find("//locals/local/@dir",dir),"*")
			else
				this.node:=settings.sn("//global/*")
		}else if(v.mode=2){
			this.node:=settings.sn("//global/*")
		}else if(v.mode=1)
			return this.node:="",this.Clear(),this.ReBuildXML("")
		ea:=xml.ea(this.xml.ssn("//list"))
		if(ea.mode!=v.mode||ea.dir!=dir)
			this.ReBuildXML(dir),this.SetStatus()
		this.Recognize()
	}ReBuildXML(dir){
		if(v.loading)
			return
		type:=this.node.item[0].ParentNode.NodeName,ea:=xml.ea(top:=this.xml.ssn("//list"))
		if(ea.mode=v.mode&&ea.type=type)
			return top.SetAttribute("dir",dir)
		Default:=0,rem:=this.xml.ssn("//list"),rem.ParentNode.RemoveChild(rem),top:=this.xml.add("list"),top.SetAttribute("mode",v.mode),top.SetAttribute("dir",dir)
		if(v.mode=4)
			new:=this.xml.Under(top,"dir",{dir:ssn(settings.Find("//locals/local/@dir",dir),"@dir").text}),new.SetAttribute("hotkey",settings.ssn("//Keyboard/Move/Move/@Directory_" ++Default).text),new.SetAttribute("name",StrSplit(Trim(dir,"\"),"\").pop())
		parent:=this.node.item[0].ParentNode,used:=[]
		while(nn:=MoveList.node.item[A_Index-1]),ea:=xml.ea(nn)
			if(ea.hotkey)
				used[ea.hotkey]:=1
		while(nn:=MoveList.node.item[A_Index-1]),ea:=xml.ea(nn){
			if(ea.hotkey){
				next:=top.AppendChild(nn.CloneNode(1)),Hotkey:=ea.Hotkey
			}else{
				next:=top.AppendChild(nn.CloneNode(1))
				while(key:=settings.ssn("//Keyboard/Move/Move/@Directory_" ++Default).text){
					if(!used[key]){
						next.SetAttribute("hotkey",key),used[key]:=1,Hotkey:=key
						goto,MoveListWhileEnd
				}}while(A_Index<27),key:=Chr(A_Index+96){
					if(!used[key]){
						next.SetAttribute("hotkey",key),Hotkey:=key
						goto,MoveListWhileEnd
			}}}next.SetAttribute("name",StrSplit(Trim(ea.dir,"\"),"\").pop())
			MoveListWhileEnd:
			Try
				Hotkey,%hotkey%,Hotkey,On
		}this.xml.SSN("//list").SetAttribute("type",this.node.item[0].ParentNode.NodeName),this.SetStatus()
	}Recognize(){
		all:=this.xml.sn("//dir/@dir"),list:=[]
		while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
			list.push(StrSplit(Trim(aa.text,"\"),"\").pop())
		Speech.MoveList(AddList(list))
	}SetStatus(){
		this.Clear()
		all:=this.xml.sn("//dir")
		Loop,8
		{
			aa:=all.item[(A_Index-1)+this.next],ea:=xml.ea(aa)
			if(ea.dir){
				helper:=A_Index ;abbr[settings.ssn("//Controller/Move/Main/Move/@Directory_" A_Index).text]
				SB_SetText((ea.current?"*":"") ea.hotkey " - " helper ": " StrSplit(Trim(ea.dir,"\"),"\").pop(),A_Index+1)
		}}Count()
	}SetCurrent(node,noshow:=0){
		for a,b in [sn(this.node.item[0].ParentNode,"descendant-or-self::*[@current]"),this.xml.sn("//*[@current]")]
			while(aa:=b.item[A_Index-1])
				aa.RemoveAttribute("current")
		if((local:=settings.Find("//locals/local/@dir",dir:=ssn(node,"@dir").text))&&v.mode!=4&&v.Top_Level!=1)
			return v.LastMode:=v.mode,v.mode:=4,v.parent:=StrSplit(Trim(dir,"\"),"\").pop(),Count(),MoveList.Update(dir)
		dir:=ssn(node,"@dir").text,settings.Find(this.node.item[0].ParentNode,"descendant-or-self::*/@dir",dir).SetAttribute("current","yes"),this.xml.Find("//dir/@dir",dir).SetAttribute("current","yes"),num:=num:=sn(node,"preceding-sibling::*").length,div:=v.mode=4?7:8,(noshow?"":this.next:=Floor(num/div)*div),this.SetStatus(noshow),all:=cxml.Sel()
		while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
			ActionList.Move(ea.file,Trim(ssn(node,"@dir").text,"\"))
		cxml.SelectNext(),cxml.NoSelections()
	}Check(){
		if(v.mode=2)
			return settings.ssn("//global/descendant::*[@hotkey='" A_ThisHotkey "']")
		if(v.mode=3)
			m("work on the locals :)")
	}AddDirectory(dir,global){
		dir:=SubStr(dir,0,1)="\"?dir:dir "\"
		if(global=1){
			if(!settings.Find("//settings/global/dir/@dir",dir))
				new:=settings.Add("global/dir",{dir:dir,name:StrSplit(Trim(dir,"\"),"\").pop()},,1),this.Hotkey(new,settings.ssn("//settings/global"),dir),PopulateGlobal()
		}else{
			node:=this.node.item[0].ParentNode
			if(node.NodeName!="local")
				if(!node:=settings.find("//locals/local/@dir",MainTree.last))
					node:=settings.Add("locals/local",{dir:MainTree.last},,1)
			if(!settings.Find(node,"descendant::dir/@dir",dir))
				new:=settings.Under(node,"dir",{dir:dir}),this.Hotkey(new,node,dir)
		}MoveList.Update(dir)
	}Hotkey(node,parent,string){
		string:=StrSplit(Trim(string,"\"),"\").pop()
		for a,b in StrSplit(RegExReplace(StrSplit(Trim(string,"\"),"\").pop(),"\s")){
			StringLower,b,b
			if(!ssn(parent,"descendant::*[@hotkey='" b "']")){
				Try
					Hotkey,%b%,deadend,On
				Catch
					Continue
				return node.SetAttribute("hotkey",b)
		}}while(A_Index<27),key:=Chr(A_Index+96)
			if(!ssn(parent,"descendant::*[@hotkey='" key "']")){
				Try
					Hotkey,%key%,deadend,On
				Catch
					Continue
				return node.SetAttribute("hotkey",key)
}}}
Movement(direction){
	tab:=Tab()
	ControlGetFocus,Focus,% MainWin.ID
	ControlGet,hwnd,hwnd,,%Focus%,% MainWin.ID
	WinGetClass,class,ahk_id%hwnd%
	if(direction~="(Next|Previous)_Control"){
		return %direction%()
	}
	if(tab=1)
		Selection(direction)
	else if(class~="TreeView|ListView")
		Send,{%direction%}
	else
		(direction~="Left|Up"?Previous_Control():Next_Control())
}
t(x*){
	for a,b in x
		obj:=StrSplit(b,":"),obj.1="time"?(time:=obj.2):(list.=b "`n")
	if(!time)
		SetTimer,grr,Off
	Tooltip,% list
	if(time)
		SetTimer,grr,% (time*1000)*-1
	return
	grr:
	t()
	return
}
m(x*){
	static list:={btn:{oc:1,ari:2,ync:3,yn:4,rc:5,ctc:6},ico:{"x":16,"?":32,"!":48,"i":64}},count:=[]
	count.push(1)
	goto,mt
	return
	mt:
	list.title:="Image-Sort",list.def:=0,list.time:=0,value:=0,v.MsgBox:=1
	for a,b in x
		obj:=StrSplit(b,":"),(vv:=List[obj.1,obj.2])?(value+=vv):(list[obj.1]!="")?(List[obj.1]:=obj.2):txt.=b "`n"
	Sleep,2
	MsgBox,% (value+262144+(list.def?(list.def-1)*256:0)),% list.title,%txt%,% list.time
	count.pop()
	if(!count.1)
		v.MsgBox:=0
	for a,b in {OK:value?"OK":"",Yes:"YES",No:"NO",Cancel:"CANCEL",Retry:"RETRY"}
		IfMsgBox,%a%
			return b
	return
}
Navigation(x){
	count:=MainWin[].Count
	node:=DirList.ssn("//*[@tv='" cxml.Current("tv") "']")
	number:=sn(node,"preceding-sibling::*").length
	max:=DirList.sn("//item").length
	if(InStr(x,"_Control"))
		return function:=x,%function%()
	if(x="First_Image")
		cxml.BuildList()
	if(x="Back")
		cxml.BuildList(DirList.ssn("//list/item[" (number-count>0?number-count:max-count)+1 "]"))
	if(x="Forward"||x="Next")
		cxml.BuildList(DirList.ssn("//item[" (number+count<=max?number+count:1)+1 "]"))
	if(IsFunc(x))
		%x%()
}
Next(action:=""){
	tab:=Tab()
	ControlGetFocus,focus,% MainWin.ID
	if(InStr(focus,"SysTreeView32")){
		Default(Focus)
		if(TV_GetChild(TV_GetSelection())){
			if(TV_Get(TV_GetSelection(),"Expand"))
				TV_Modify(TV_GetSelection(),"-Expand")
			else
				TV_Modify(TV_GetSelection(),"Expand")
		}
		return
	}
	if(tab!=1){
		Send,{Enter}
		return
	}
	if(v.compare.ssn("//item")){
		rem:=v.compare.ssn("//item"),rem.ParentNode.RemoveChild(rem)
		if(v.compare.ssn("//item"))
			return cxml.Compare()
	}
	if(v.help)
		return
	if(v.showimage)
		return Selection("Right")
	ControlGetFocus,Focus,% mainwin.id
	Default(Focus)
	if(action="Next"){
		last:=v.showimage?cxml.Current():cxml.xml.ssn("//list").LastChild
		file:=DirList.find("//@file",ssn(last,"@file").text)
		next:=file.NextSibling?file.NextSibling:file.ParentNode.FirstChild
		cxml.BuildList(next)
		/*
			cxml.ClearList()
			cxml.Populate(ssn(next,"@file").text)
			cxml.SetCurrent(cxml.xml.ssn("//list/item[1]"))
			Display()
			cxml.Highlight()
		*/
	}
}
Number(first:=""){
	return first?sn(DirList.find("//@file",ssn(first,"@file").text),"preceding-sibling::*").length:0
}
PopulateGlobal(){
	Default("SysListView321",1),LV_Delete(),all:=settings.sn("//global/dir"),last:=settings.ssn("//settings/global/@last").text
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
		dir:=StrSplit(Trim(ea.dir,"\"),"\").pop(),ctrl.Add("GlobalMoveDirectories",(last=dir?"Select Vis Focus":""),dir,Convert_Hotkey(ea.Hotkey),ea.dir)
	}
	ctrl.AutoHDR("Global",3)
	if(!last)
		LV_Modify(1,"Select Vis Focus")
}
PopulateHotkeys(startup:=0){
	static TreeView:=[]
	Default("SysTreeView323"),TV_Delete()
	all:=settings.sn("//Keyboard/descendant::*")
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa)
		if(aa.HasChildNodes())
			TreeView[TV_Add(aa.NodeName (ea.screen?" " ea.screen:""))]:=aa
	if(startup&&name:=settings.ssn("//last/@HotkeysTV").text)
		for a,b in TreeView
			if(b.nodename=name)
				TV_Modify(a,"Select Vis Focus")
	return
	HotkeyLV:
	settings.Add("last").SetAttribute(ctrl.GetText("HotkeysTV"),ctrl.GetText("HotkeysLV"))
	return
	PopKeys:
	if(node:=(TreeView[A_EventInfo]?TreeView[A_EventInfo]:TreeView[ctrl.GetTV("HotkeysTV")])){
		settings.Add("last").SetAttribute("HotkeysTV",node.NodeName),Default("SysListView323"),ctrl.NoRedraw("HotkeysLV"),LV_Delete(),v.ListView:=[],nodes:=sn(node,"descendant::*"),default:=settings.ssn("//last/@" node.NodeName).text
		while(nn:=nodes.item[A_Index-1]){
			LV_Add("","---" nn.nodename "---"),att:=sn(nn,"@*")
			while(aa:=att.item[A_Index-1]),ea:=xml.ea(aa)
				v.ListView[LV_Add((default&&aa.NodeName=default?"Select Vis Focus":""),aa.NodeName,Convert_Hotkey(aa.Text),Convert_Hotkey(settings.ssn("//Controller/" nn.ParentNode.NodeName "/Main/" nn.NodeName "/@" aa.NodeName).text),Convert_Hotkey(settings.ssn("//Controller/" nn.ParentNode.NodeName "/Alt/" nn.NodeName "/@" aa.NodeName).text))]:={nodename:nn.nodename,node:aa}
		}
		ctrl.AutoHDR("HotkeysLV",3)
		if(!Default)
			LV_Modify(1,"Select Vis Focus")
		ctrl.Redraw("HotkeysLV")
	}
	return
}
PopulateLocal(){
	static count:=0
	Default("SysListView322",1),LV_Delete(),ctrl.NoRedraw("local"),list:=MoveList.node,ListView:=[],v.mode=4?(main:=MoveList.node.item[0].ParentNode):(main:=settings.Find("//locals/local/@dir",MainTree.last)),localdir:=ssn(main,"@last").text,list:=sn(main,"*")
	while(aa:=list.item[A_Index-1]),ea:=xml.ea(aa)
		ListView[dir:=StrSplit(Trim(ea.dir,"\"),"\").pop()]:=ctrl.Add("LocalMoveDirectories",(localdir=dir?"Select Vis Focus":""),dir,Convert_Hotkey(ea.Hotkey),ea.dir)
	ctrl.Redraw("local"),ctrl.AutoHDR("Local",3)
}
Press(Key){
	tab:=Tab()
	if(v.MsgBox){
		if(key~="\bUp|Down|Left|Right\b")
			Send,{%key%}
		if(key="A")
			Send,{Space}
		if(key="B"){
			WinGetText,text,A
			if(InStr(text,"&No"))
				Send,!n
		}
		return
	}
	if(!WinActive(MainWin.ID)){
		if(key~="\bUp|Down|Left|Right\b")
			Send,{%key%}
		if(key="A")
			Send,{Enter}
		if(key="B")
			Send,{Escape}
		return
	}
	if(!WinActive(MainWin.id)){
		if(key="Back")
			Send,{Escape}
		else if(key="Start")
			Send,{Enter}
		else if(settings.SSN("//*[@Previous_Control='" key "']"))
			Send,+{Tab}
		else if(settings.SSN("//*[@Next_Control='" key "']"))
			Send,{Tab}
		else if(node:=settings.Find("//Controller/descendant::Movement/@node()",key,0)){
			direction:=node.NodeName
			Send,{%direction%}
		}
		return
	}
	if(tab=4){
		if(v.EditingControllerInput)
			return EditControllerAction(key)
		else if(key~="\bA|B\b")
			return EditControllerAction(key)
		if(node:=settings.Find("//Controller/Global/descendant::*/@node()",key,0)),function:=ssn(node,"..").NodeName{
			if(IsFunc(function))
				return %function%(node.NodeName)
		}
	}
	Action(key,0,v.held[settings.ssn("//Controller/Global/Main/Alt/@Alt").text])
}
Next_Control(){
	Control("next")
}
Previous_Control(){
	Control("previous")
}
Control(move){
	ControlGetFocus,focus,% MainWin.id
	ControlGet,hwnd,hwnd,,%focus%,% MainWin.id
	node:=MainWin.XML.ssn("//*[@tab='" Tab() "']/descendant::*[@hwnd='" hwnd+0 "']"),select:=move="next"?(node.nextSibling?node.nextSibling:node.ParentNode.FirstChild):(node.previousSibling?node.previousSibling:node.ParentNode.lastchild),select:=select?select:node.FirstChild
	ControlFocus,,% "ahk_id" ssn(select,"@hwnd").text  ;,% MainWin.ID
}
Properties(value:=""){
	KeyWait,Alt,U
	img:=ComObjCreate("WIA.ImageFile"),img.LoadFile((ea:=cxml.CurrentEA()).file),item:=wb.getelementbyid(ea.file),m("HRes=" img.HorizontalResolution,"VRes=" img.VerticalResolution,"PixelDepth=" img.PixelDepth,"Extended Pixels=" img.IsExtendedPixelFormat,"Frames=" img.FrameCount,"Image Format=" img.FormatID,"File Extension=" img.FileExtension,"Image Width=" img.width,"Image Height=" img.height,"IsIndexed=" img.IsIndexedPixelFormat,"IsAlphaPixelFormat=" img.IsAlphaPixelFormat,"Displayed Width=" item.width,"Displayed Height=" item.height)
}
Quick_Jump(){
	static
	QJ:=new DirSelect("Quick_Jump","Quick Jump",1)
	return
	Quick_JumpEscape:
	Quick_JumpClose:
	m(QJ.dir.last)
	QJ.Close()
	return
	/*
		Gui,Quick_Jump:Destroy
		Gui,Quick_Jump:Default
		quick:=new DirTree("Quick_Jump","w500 h500",,MainTree.last)
		Gui,Add,Edit,w500 gcheckdir vcheckdir,% MainTree.last
		Default("SysTreeView321","Quick_Jump"),TV_Modify(TV_GetSelection(),"+Expand")
		Gui,Quick_Jump:Show,,Quick Jump
		return
		checkdir:
		Gui,Quick_Jump:Submit,Nohide
		if(FileExist(checkdir)){
			Loop,Files,%checkdir%,D
			{
				if(node:=quick.xml.Find("//@dir",A_LoopFileLongPath "\")){
					TV_Modify(ssn(node,"@tv").text,"Select VisFirst Focus")
				}else
					quick.Build(A_LoopFileLongPath)
		}}
		return
		Quick_JumpGuiEscape:
		Quick_JumpGuiClose:
		Sleep,1
		MainTree.Build(quick.last)
		Gui,Quick_Jump:Destroy
		return
	*/
}
RButton(){
	tab:=Tab()
	if(tab=1){
		Run,% MainTree.last
		return
	}if(tab=2){
		m("Tab2")
	}if(tab=3){
		ControlGetFocus,Focus,% MainWin.ID
		if(Focus="SysListView321"){
			Gui,1:Default
			Gui,1:TreeView,SysTreeView321
			TV_Modify(xml.ea(MainTree.xml.Find("//@dir",ctrl.GetText("Global","",3))).tv,"Select Vis Focus")
		}
	}
}
Refresh_Directory_List(){
	MainTree.Refresh()
}
ReOrder(action){
	ControlGetFocus,Focus,% MainWin.ID
	m(focus,action)
}
Screen(x){
	Tab(x)
}
Select(info:=""){
	if(info="clear")
		return cxml.ClearSel(),cxml.Highlight()
	else if(info="all"){
		all:=cxml.List()
		while,aa:=all.item[A_Index-1],ea:=xml.ea(aa){
			if(rem:=cxml.xml.ssn("//selected/item[@tv='" ea.tv "']"))
				rem.ParentNode.RemoveChild(rem)
			else
				cxml.xml.ssn("//selected").AppendChild(aa.CloneNode(1))
		}cxml.Highlight()
}}
Selection(dir:=""){
	if(Tab()=1){
		if(dir="Select_All"){
			all:=cxml.xml.sn("//list/item"),top:=cxml.xml.add("selected")
			while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
				if(node:=cxml.xml.find("//selected/descendant::*/@file",ea.file))
					node.ParentNode.RemoveChild(node)
				else
					top.AppendChild(aa.CloneNode(1))
			}cxml.Highlight()
			/*
				sel:=cxml.xml.sn("//item"),remove:=[],add:=[],top:=cxml.xml.add("selected")
				while(ss:=sel.item[A_Index-1]),ea:=xml.ea(ss){
					if(node:=cxml.xml.find("//selected/descendant::*/@file",ea.file))
						remove.push(node)
					else
						add.push(ss.CloneNode(1))
				}
				for a,b in remove
					b.ParentNode.RemoveChild(b)
				for a,b in add
					top.AppendChild(b)
				cxml.Highlight()
			*/
			return
		}
		if(dir="select"){
			cxml.Select()
			if(v.showimage)
				ea:=cxml.CurrentEA(),node:=DirList.ssn("//*[@tv='" ea.tv "']"),next:=node.NextSibling?node.NextSibling:node.ParentNode.FirstChild,cxml.BuildList(next)
			return
		}if(dir="Next"){
			return Next("Next")
		}if(dir="Toggle_FullScreen")
			return v.showimage:=v.showimage?0:1,cxml.BuildList(cxml.Current())
		current:=cxml.Current(),v.help:=0
		if(!v.showimage){
			if(dir="left")
				next:=current.PreviousSibling?current.PreviousSibling:current.ParentNode.LastChild
			if(dir="right")
				next:=current.NextSibling?current.NextSibling:current.ParentNode.FirstChild
			if(dir="up"&&v.showimage!=1){
				pre:=sn(current,"preceding-sibling::*").length
				if((item:=pre-v.x+1)<1){
					right:=mod(pre,v.x),item:=v.x*(v.y-1)+right+1
					if(item>wb.images.length)
						item:=(last:=v.x*(v.y-2)+right+1)
				}
				next:=cxml.xml.ssn("//list/item[" item "]")
			}
			if(dir="down"&&v.showimage!=1)
				total:=cxml.xml.sn("//list/*").length,xy:=xml.ea(current.ParentNode),pre:=sn(current,"preceding-sibling::*").length,next:=ssn(current.ParentNode,"item[" (pre+v.x<total?pre+v.x+1:Mod(pre,v.x)+1) "]")
			if(next)
				cxml.SetCurrent(next)
			cxml.Highlight()
		}else{
			ea:=xml.ea(current)
			node:=DirList.find("//@file",ea.file)
			if(dir~="Up|Left")
				next:=node.PreviousSibling?node.PreviousSibling:node.ParentNode.LastChild
			else
				next:=node.NextSibling?node.NextSibling:node.ParentNode.FirstChild
			if(next)
				cxml.BuildList(next)
			/*
				node:=cxml.xml.ssn("//list/item"),node.ParentNode.ReplaceChild(next.CloneNode(1),node),cxml.ssn("//list/item").SetAttribute("current","yes"),Display(),cxml.Highlight()
			*/
		}
		if(next)
			cxml.SetLast(next)
		ea:=xml.ea(cxml.current())
		if(!ea.delete&&!ea.rename)
			cxml.Last()
		else
			DelRen()
	}if(Tab()>1){
		Send,{%dir%}
	}Count()
}
SetTitle(){
	title:="Image Sort"
	if(settings.ssn("//automove").text)
		title.=": AutoMove"
	if(v.startxbox||v.nocontroller)
		title.=": Press " Convert_Hotkey(settings.SSN("//Keyboard/Global/XBox/@Activate_XBox_Controller").text) " to start your XBox controller"
	title.=": " SplitPath(ssn(cxml.Current(),"@file").text).file,images:=wb.images.length
	voice:=Speech.Enabled=0?"":Speech.Commands?"Voice Commands: Say 'Exit' when finished":Speech.select?"Voice Select: Say 1 - " wb.images.length " : Say 'Exit' When Finished":Speech.Enabled?"Voice Enabled: Say (Help" (Tab()=1&&!v.Help?",Commands, or What Can I Say":"") ")":"Press " settings.SSN("//Keyboard/descendant::*/@Help").text " for Help"
	WinSetTitle,% mainwin.id,,%title% - %images% Images %voice%
}
SplitPath(file){
	SplitPath,file,filename,dir,ext,nne,drive
	if(dir)
		return {file:filename,dir:dir "\",ext:ext,nne:nne,drive:drive}
}
Tab(Direction:=""){
	ControlGet,tab,tab,,SysTabControl321,% MainWin.ID
	if(v.Help&&Direction)
		return Help(Direction)
	if(!Direction)
		return tab
	if(Direction~="Previous|Next"){
		next:=tab+(Direction~="Previous"?-1:1),next:=next>0&&next<=v.tabmax?next:Direction~="Previous"?v.tabmax:1
		GuiControl,1:Choose,SysTabControl321,%next%
		if(control:=MainWin.XML.ssn("//tab[@tab='" next "']/control/@hwnd").text)
			ControlFocus,,ahk_id%control%
	}
	ControlGet,tab,tab,,SysTabControl321,% MainWin.ID
	if(tab=3)
		PopulateLocal()
	SetTitle()
	if(Speech.commands)
		Speech.ToggleScreen(1)
	/*
		ONLY DO THIS IF YOU ARE USING THE HELP...I think...
		WinSet,Redraw,,% MainWin.ID
	*/
}
Toggle_Voice_Commands(){
	if(!Speech.AudioInputs)
		return m("Can not start the Voice Recognition, There are no audio inputs.")
	Speech.grammar.CmdSetRuleState("Move",Speech.enabled:=Speech.enabled?0:1),settings.add("Options",{Voice:Speech.enabled}),SetTitle()
}
TopLevel(set:=1){
	if(set)
		v.Top_Level:=MainWin[].TopLevel,settings.Add("Options",{Top_Level:v.Top_Level})
	GuiControl,,% MainWin.xml.ssn("//tab[@tab='5']/control[@track='TopLevel']/@hwnd").text,% v.Top_Level
}Top_Level(){
	v.Top_Level:=v.Top_Level?0:1,TopLevel(0),settings.Add("Options",{Top_Level:v.Top_Level})
}
Undo(){
	static nw,file
	file:=cxml.Current("file"),nw:=new GUIKeep("Undo"),nw.Add("TreeView,w800 h400 gundoshow AltSubmit,,wh","Button,xm w800 gundogo Default,Undo (Enter),wy"),v.default:=nw.id,all:=ActionList.undo.sn("//action"),Default("SysTreeView321","Undo")
	while,aa:=all.item[A_Index-1]{
		items:=sn(aa,"*"),aa.SetAttribute("tv",TV_Add(FormatTime(ssn(aa,"@time").text)))
		while,ii:=items.item[A_Index-1],ea:=xml.ea(ii)
			ii.SetAttribute("tv",TV_Add(StrSplit(ea.old,"\").pop() " -> " ea.new,ssn(ii.ParentNode,"@tv").text))
	}nw.show("Undo")
	return
	undoshow:
	if(A_GuiEvent!="S")
		return
	count:=MainWin[].count
	if((list:=ActionList.undo.sn("//*[@tv='" A_EventInfo "']/*")).length){
		top:=cxml.ClearList()
		while(ll:=list.item[A_Index-1]),ea:=xml.ea(ll){
			top.AppendChild(ll.CloneNode(1))
			if(sn(top,"*").length>=count)
				Break
		}Display(),cxml.Highlight()
	}else if(node:=ActionList.undo.ssn("//*[@tv='" A_EventInfo "']"))
		list:=cxml.ClearList(),list.AppendChild(node.CloneNode(1)),Display(),cxml.Highlight()
	WinSetTitle,% nw.ID,,% "Undo - Showing " sn(top,"*").length " of " length
	return
	undogo:
	Gui,Undo:Default
	Default("SysTreeView321","Undo"),sel:=TV_GetSelection(),node:=ActionList.undo.ssn("//*[@tv='" sel "']"),parent:=node.ParentNode,next:=node.nextSibling?node.nextSibling:node.previousSibling,TV_Delete(sel),((tv:=ssn(next,"@tv").text)?TV_Modify(tv,"Select Vis Focus"):"")
	if((list:=ActionList.undo.sn("//*[@tv='" sel "']/*")).length){
		while(ll:=list.item[A_Index-1]),ea:=xml.ea(ll)
			FileMove,% ea.new,% Unique(ea.old)
		node.ParentNode.RemoveChild(node)
	}else if(ea:=ActionList.undo.ea("//*[@tv='" sel "']")){
		FileMove,% ea.new,% Unique(ea.old)
		node.ParentNode.RemoveChild(node)
	}
	return
	UndoEscape:
	UndoClose:
	all:=ActionList.undo.sn("//action")
	while(aa:=all.item[A_Index-1]),ea:=xml.ea(aa){
		if(!aa.HasChildNodes())
			aa.ParentNode.RemoveChild(aa)
	}
	SetTimer,NotifyRefresh,-1
	Sleep,200
	cxml.ClearList(),cxml.Populate(file,1),Display(),cxml.Highlight(),v.Default:=""
	Gui,Undo:Destroy
	return
}
Unique(file){
	if(!FileExist(file))
		return file
	SplitPath,file,,dir,ext,nne
	newfile:=dir "\" nne "." ext
	while(FileExist(newfile))
		newfile:=dir "\" nne "(" A_Index ")." ext
	return newfile
}
class EditHotkey{
	__New(return,MN){
		static
		if(mn.nodetype=2){
			first:=0
			MainNode:=ssn(MN,"..")
			current:=MN
		}else{
			MainNode:=MN.ParentNode,first:=1
			current:=MN
		}
		default:=default?ssn(default,"@hotkey").text:""
		Gui,Hotkeys:Destroy
		Gui,Hotkeys:Default
		Gui,Add,Hotkey,vhotkey w300 gEHotkey,%Default%
		Gui,Add,Edit,vedit w300 gEHEdit,
		Gui,Add,ListView,w300 h200,Duplicate
		Gui,Add,Button,gHotkeysGuiEscape Default,Set Hotkey
		Gui,Add,Button,x+0 gHotkeysGuiClose,Cancel
		Gui,Show,,Hotkeys
		func:=Func(return)
		return
		EHEdit:
		Gui,Submit,Nohide
		if(InStr(Edit,"'")){
			GuiControl,Hotkeys:,msctls_hotkey321
			GuiControl,Hotkeys:,Edit1
			return m("Sorry, but ' can not be a hotkey or part of a hotkey")
		}
		GuiControl,Hotkeys:,msctls_hotkey321,%edit%
		return
		EHotkey:
		Gui,Hotkeys:Submit,Nohide
		hotkey:=hotkey?hotkey:edit
		if(InStr(hotkey,"'")){
			GuiControl,Hotkeys:,msctls_hotkey321
			GuiControl,Hotkeys:,Edit1
			return m("Sorry, but ' can not be a hotkey or part of a hotkey")
		}
		Default("SysListView321","Hotkeys"),LV_Delete()
		dup:=sn(MainNode.ParentNode,"descendant::*/@node()[.='" Hotkey "']"),dup:=dup.length?dup:settings.SN("//Keyboard/Global/descendant::*/@node()[.='" Hotkey "']")
		while(dd:=dup.item[A_Index-1]),ea:=xml.ea(dd)
			LV_Add("",dd.nodename!=current.nodename?dd.nodename:"This Is This Options Current Hotkey")
		return
		HotkeysGuiClose:
		Gui,Hotkeys:Destroy
		return
		HotkeysGuiEscape:
		Gui,Hotkeys:Submit,NoHide
		Gui,Hotkeys:Destroy
		if(!Hotkey&&Edit){
			Try
				Hotkey,%Edit%,Hotkey,On
			Catch
				return m("Invalid hotkey")
			hotkey:=edit
		}
		%func%([hotkey])
		return
		deadend:
		return
}}
SetCount(){
	Speech.Numbers()
}
Help(help:="Toggle"){
	static info:={1:["Use your arrow keys to move the selection","Press Space to select/de-select an item","Press Ctrl+A to toggle the selected state of all of the images","Use Alt+Left/Right to change between screens"]
				  ,2:["Select a directory to view images from","Images will be sorted by type"]
				  ,3:["Add items to eiter Global or Local"]
				  ,4:["Bind hotkeys and controller buttons to specific functions"]
				  ,5:["Set the count number to how many images you want to show up when you hit Enter"]}
				  ,header:={1:"Images",2:"Folders and Files",3:"Move Directories",4:"Hotkeys & Controller Settings",5:"General Settings"}
	if(help="Toggle")
		v.help:=v.help?0:1
	if(v.help){
		if(rem:=wb.GetElementsByTagName("div").item[0])
			rem.ParentNode.RemoveChild(rem)
		if(!v.helptab){
			v.helptab:=Tab()
		}else
			v.helptab:=help="Previous_Screen"?(v.helptab-1>0?v.helptab-1:header.MaxIndex()):(v.helptab+1<=header.MaxIndex()?v.helptab+1:1)
		html:="<div style='overflow:auto;'><div style='margin:10 40px !important;background-color=#ffffff;text-align:center;'><header><h1>Help: " header[v.helptab] "</h1><h5>Press F1 to Open/Close this Help Screen</h5></header></div><div style='margin:10 40px !important;background-color:#ffffff'><p style='background-color:#ffffff'><a id='Left' style='float:left;cursor:hand;color:#0000ff;background-color:#ffffff;'><----" header[v.helptab-1<1?header.MaxIndex():v.helptab-1] "</a><a id='Right' style='float:right;cursor:hand;color:#0000ff;background-color:#ffffff;'>" header[v.helptab+1>header.MaxIndex()?1:v.helptab+1] "----></a></p></br></div></br></br><div style='margin:10 40px !important;background-color=#ffffff;text-align:center;margin-bottom:10px;margin-top:10px;'>"
		for a,b in info[v.helptab]
			html.="<p>" b "<p>"
		html.="</div></div></div>",wb.body.innerhtml:=html,wb.GetElementsByTagName("div").item[0].style.height:=mainwin.WinPos().h
		GuiControl,1:Choose,SysTabControl321,1
	}else{
		GuiControl,1:Choose,SysTabControl321,% v.helptab
		rem:=wb.GetElementsByTagName("div").item[0],rem.ParentNode.RemoveChild(rem),div:=wb.CreateElement("div"),wb.body.InnerHtml:="<!DOCTYPE html><html><body leftmargin=0 topmargin=0 rightmargin=0 bottommargin=0></body><div></div></html>",wb.body.style.backgroundcolor:=0,Display(),cxml.Highlight()
		if(v.helptab=1)
			GuiControl,1:+Redraw,AtlAxWin1
		v.helptab:=0
	}SetTitle()
}