$PBExportHeader$n_picture_masker.sru
$PBExportComments$PictureButton masker by Dmitry Lukyanov <ldu@writeme.com>
forward
global type n_picture_masker from nonvisualobject
end type
type str_rect from structure within n_picture_masker
end type
type str_imageinfo from structure within n_picture_masker
end type
type str_drawitemstruct from structure within n_picture_masker
end type
end forward

type str_rect from structure
	long		left
	long		top
	long		right
	long		bottom
end type

type str_imageinfo from structure
	long		hbm_image
	long		hbm_mask
	long		unused1
	long		unused2
	str_rect		rc_image
end type

type str_drawitemstruct from structure
	long		ctl_type
	long		ctl_id
	long		item_id
	long		item_action
	long		item_state
	long		item_hwnd
	long		hdc
	str_rect		item_rc
	long		item_data
end type

global type n_picture_masker from nonvisualobject autoinstantiate
end type

type prototypes
//ImageList functions
function long ImageList_GetIcon(long imglist,long index,long flags) library "comctl32.dll"
function long ImageList_Create(int cx, int cy, long flags, int cInitial, int cGrow) library "comctl32.dll"
function boolean ImageList_Destroy(long himglist) library "comctl32.dll"
function int ImageList_AddMasked(long himglist, long hbmImage, long colorMask) library "comctl32.dll"
function int ImageList_Add(long himglist, long hbmImage, long hbmpMask) library "comctl32.dll"
function long ImageList_SetBkColor(long himglist, long bgColor) library "comctl32.dll"
function boolean ImageList_Draw(long imgList, int i,long hdcDst,int x,int y,long fStyle) library "comctl32.dll"
function boolean ImageList_GetImageInfo(long imglist, int i, ref str_imageinfo pImageInfo ) library "comctl32.dll"
//DC functions
function long GetDC(long hwnd) library "user32.dll"
function long CreateCompatibleDC(long hdc) library "gdi32.dll"
function boolean ReleaseDC(long hwnd, long hdc)library "user32.dll"
function boolean DeleteDC(long hdc) library "gdi32.dll"

function long SelectObject(long hdc, long handle) library "gdi32.dll"
// Get/Set Window long functions (for style changing)
function long GetWindowLong(long hWnd, long nIndex) library "user32.dll" alias for GetWindowLongA
function long SetWindowLong(long hWnd, long nIndex, long dwNewLong)library "user32.dll" alias for SetWindowLongA
//gdi draw functions
function long CreateCompatibleBitmap(long hdc, int nWidth, int nHeight) library "gdi32.dll"
function long CreateBitmap(long w, long h, long panels, long bits, long data) library "gdi32.dll"
function boolean BitBlt(long hdcDest, long nXDest, long nYDest, long nWidth, long nHeight, long hdcSrc,long nXSrc, long nYSrc, long dwRop) library "gdi32.dll"
function boolean DeleteObject(long hObject)library "gdi32.dll"
function long CreateSolidBrush(long crColor) library "gdi32.dll"
function long SetBkMode(long hdc,int iBkMode) library "gdi32.dll"
function long SetBkColor(long hdc, long crColor) library "gdi32.dll"
function long SetTextColor(long hdc, long crColor) library "gdi32.dll"
 
// user32 draw functions
function boolean DestroyIcon(long hicon) library "user32.dll"
function boolean FillRect(long hDC, ref str_rect lprc, long hbrush) library "user32.dll"
function long DrawText(long hDC, ref string text, long nCount, ref str_rect lpRect, long uFormat) library "user32.dll" alias for DrawTextA
function long CopyImage(long hImage, long uType, long cxDesired, int cyDesired,long fuFlags) library "user32.dll"
//
function long SendMessage(long handle,long msg,long ctrl_id,ref str_drawitemstruct dis) library "user32.dll" alias for SendMessageA
//
function long GetDlgCtrlID(long hwnd) library "user32.dll"
function long GetPixel(long hdc,long x,long y) library "gdi32.dll"
function long SetPixel(long hdc,long x,long y,long color) library "gdi32.dll"
function boolean FrameRect(long hDC,ref str_rect rc,long hbr) library "user32.dll"
function long CreateWindowEx(long exStyle,string class_name,string Window_Name, ulong dwStyle,int x,int y,int nWidth,int nHeight,long hWndParent, long hMenu, long hInstance, long lpParam) library "user32.dll" alias for CreateWindowExA
function long GetSysColor(long index) library "user32.dll"
function long FindWindowEx(long hwndParent,long hwndChildAfter,string Class,string Title) library "user32.dll" alias for FindWindowExA
function boolean SetWindowPos(long hWnd,long hWndInsertAfter,long X,long Y,long cx,long cy,ulong uFlags) library "user32.dll"
function boolean DestroyWindow(long hWnd) library "user32.dll"

end prototypes

type variables

end variables

forward prototypes
private subroutine f_initrect (readonly str_rect rc, integer left, integer top, integer right, integer bottom)
public function boolean f_reset (readonly picturebutton pb)
public function boolean f_is_masked (readonly picturebutton pb)
public function boolean f_setmask (readonly picturebutton pb)
public function boolean f_reset (readonly picture pic)
public function boolean f_setmask (readonly picture pic)
private function unsignedlong f_and (unsignedlong a1, unsignedlong a2)
public function boolean f_mapcolor (long dst_hdc, long w, long h, long color_from, long color_to)
end prototypes

private subroutine f_initrect (readonly str_rect rc, integer left, integer top, integer right, integer bottom);
rc.left=left
rc.top=top
rc.right=right
rc.bottom=bottom

end subroutine

public function boolean f_reset (readonly picturebutton pb);boolean ret
if isValid(pb) then
	if f_is_masked(pb) then
		long pbh
		ulong style
		long hicon
		pbh=handle(pb)
		hicon=Send(pbh,246,1,0) //BM_GETIMAGE(IMAGE_ICON,0)
		//if hicon<>0 then DestroyIcon(hicon)//produces a low resource error
		
		style=GetWindowLong(pbh,-16)
		style=f_and(style,4294901760)+11// ( style & 0xFFFF0000 ) | BS_OWNERDRAW
		SetWindowLong(pbh,-16,style)	//SET NEW STYLE
		ret=true
	end if
end if

return ret

end function

public function boolean f_is_masked (readonly picturebutton pb);long style

style=GetWindowLong(handle(pb),-16)
style=f_and(style,65535)// ( style & 0x0000FFFF )

return style=64 //BS_ICON

end function

public function boolean f_setmask (readonly picturebutton pb);boolean ret=false

long						w,h	//width and height of the button
long						delta=3	//margin in pixels that bowerbuilder uses to draw button borders
long						pb_hwnd
boolean					enabled
long						parent_hwnd
str_drawitemstruct	dis
str_rect					rc
long						wnd_dc
long						bmp_dc
long						hbmp
long						old_bmp
long						ctrl_id
long						bgcolor
long						hbrush
long						imglist
long						icon
long						imageNo
ulong						style

if isValid(pb) then
	//remember old status
	enabled=pb.enabled
	//set new status to true
	pb.enabled=true
	//get size of the picturebutton
	w=UnitsToPixels(pb.width,XUnitsToPixels!)
	h=UnitsToPixels(pb.height,YUnitsToPixels!)
	if w<delta*2+1 or h<delta*2+1 then goto error
	
	//get picturebutton handle
	pb_hwnd=handle(pb)
	//get pb parent handle
	parent_hwnd=handle(pb.getParent())
	f_initrect(rc,0,0,w,h)
	wnd_dc=GetDC(pb_hwnd)
	bmp_dc=CreateCompatibleDC(wnd_dc)
	hbmp=CreateCompatibleBitmap(wnd_dc,w,h)
	old_bmp=SelectObject(bmp_dc,hbmp)
	ctrl_id=GetDlgCtrlID(pb_hwnd)
	
	dis.ctl_type=4	//ODT_BUTTON
	dis.ctl_id=ctrl_id
	dis.item_id=0	//no items in button
	dis.item_action=1	//ODA_DRAWENTIRE
	dis.item_state=0
	dis.item_hwnd=pb_hwnd;	//maybe parent?
	dis.hdc=bmp_dc
	dis.item_rc=rc
	dis.item_data=0
	//send drawitem message to make powerbuilder to draw into bmp his button
	SendMessage(parent_hwnd,43,ctrl_id,dis)	//WM_DRAWITEM
	
	//get background color from the first picture pixel
	bgcolor=GetPixel(bmp_dc,delta,delta)
	
	//remove button border
	hbrush=CreateSolidBrush(bgcolor)
	FrameRect(bmp_dc,rc,hbrush)
	f_initrect(rc,rc.left+1,rc.top+1,rc.right -1,rc.bottom -1)
	FrameRect(bmp_dc,rc,hbrush)
	f_initrect(rc,rc.left+1,rc.top+1,rc.right -1,rc.bottom -1)
	FrameRect(bmp_dc,rc,hbrush)
	SelectObject(bmp_dc,old_bmp)
	old_bmp=0
	imgList=ImageList_Create(w,h,16+1,1,1)//ILC_COLOR16+ILC_MASK 	
	imageNo=ImageList_AddMasked(imgList,hbmp,bgcolor)
	if imageNo<0 then goto error
	//get picture as icon
	icon=ImageList_GetIcon(imgList,imageNo,0)
	if icon=0 then goto error
	//try to copy icon
	icon=CopyImage(icon, 1,	w,	h,	4)
	if icon=0 then goto error
	//set style icon for button
	style=GetWindowLong(pb_hwnd,-16)
	style=f_and(style,4294901760)+64// ( style & 0xFFFF0000 ) | BS_ICON 
	if pb.default then style+=1	//|BS_DEFPUSHBUTTON
	//SET NEW STYLE
	if SetWindowLong(pb_hwnd,-16,style)=0 then goto error
	
	//set icon for button
	icon=Send(pb_hwnd,247,1,icon)	//BM_SETIMAGE,ICON
	if icon<>0 then
		//destroy old icon if we have one
		//DestroyIcon(icon)//produces a low resource error
	end if

	
	ret=true
	error:
	if imgList<>0 then ImageList_Destroy(imgList)
	if old_bmp<>0 then SelectObject(bmp_dc,old_bmp)
	if hbrush<>0 then DeleteObject(hbrush)
	if hbmp<>0 then DeleteObject(hbmp)
	if bmp_dc<>0 then DeleteDC(bmp_dc)
	if wnd_dc<>0 then ReleaseDC(pb_hwnd,wnd_dc)

	//return old enabled state
	pb.enabled=enabled
end if

return ret

end function

public function boolean f_reset (readonly picture pic);boolean ret=false

long static_hwnd
long parent_hwnd
long hbmp

parent_hwnd=Handle(pic.getParent())
static_hwnd=FindWindowEx(parent_hwnd,0,"STATIC",pic.classname())
if static_hwnd<>0 then
	hbmp=Send(static_hwnd,371,0,0)
	if hbmp<>0 then DeleteObject(hbmp)
	DestroyWindow(static_hwnd)
end if
pic.visible=true
return ret

end function

public function boolean f_setmask (readonly picture pic);boolean ret=false

long 						ix,iy
long						w,h	//width and height of the button
long						border=0	//margin in pixels that bowerbuilder uses to draw borders
long						pb_hwnd
boolean					enabled
long						parent_hwnd
str_drawitemstruct	dis
str_rect					rc
long						wnd_dc
long						bmp_dc
long						hbmp
long						old_bmp
long						ctrl_id
long						bgcolor
long						sysbgcolor
long						hbrush

if isValid(pic) then
	//get size of the picture
	w=UnitsToPixels(pic.width,XUnitsToPixels!)
	h=UnitsToPixels(pic.height,YUnitsToPixels!)
	if w<border*2+1 or h<border*2+1 then goto error
	
	//get picturebutton handle
	pb_hwnd=handle(pic)
	//get pb parent handle
	parent_hwnd=handle(pic.getParent())
	f_initrect(rc,0,0,w,h)
	wnd_dc=GetDC(pb_hwnd)
	bmp_dc=CreateCompatibleDC(wnd_dc)
	hbmp=CreateCompatibleBitmap(wnd_dc,w,h)
	old_bmp=SelectObject(bmp_dc,hbmp)
	ctrl_id=GetDlgCtrlID(pb_hwnd)
	
	dis.ctl_type=4	//ODT_BUTTON
	dis.ctl_id=ctrl_id
	dis.item_id=0	//no items in button
	dis.item_action=1	//ODA_DRAWENTIRE
	dis.item_state=0
	dis.item_hwnd=pb_hwnd;	//maybe parent?
	dis.hdc=bmp_dc
	dis.item_rc=rc
	dis.item_data=0
	//send drawitem message to make powerbuilder to draw into bmp his button
	SendMessage(parent_hwnd,43,ctrl_id,dis)	//WM_DRAWITEM
	
	//get background color from the first picture pixel
	bgcolor=GetPixel(bmp_dc,border,border)
	sysbgcolor=GetSysColor(15)
	f_mapColor(bmp_dc,w,h,bgcolor,sysbgcolor)
	SelectObject(bmp_dc,old_bmp)
	old_bmp=0
	
	ix=UnitsToPixels(pic.x,XUnitsToPixels!)
	iy=UnitsToPixels(pic.y,YUnitsToPixels!)
	
	long static_hwnd
	
	static_hwnd=FindWindowEx(parent_hwnd,0,"STATIC",pic.classname())
	if static_hwnd=0 then
		static_hwnd=CreateWindowEx(0,"STATIC",pic.classname(), 1476395008+2062,ix,iy,w,h,parent_hwnd,0,0,0)
	else
		SetWindowPos(static_hwnd,0,ix,iy,0,0,533)		
	end if
	if static_hwnd=0 then goto error
	hbmp=Send(static_hwnd,370,0,hbmp)	//STM_SETIMAGE,BITMAP
	
	pic.visible=false
	hbmp=0
	ret=true
	error:
	if old_bmp<>0 then SelectObject(bmp_dc,old_bmp)
	if hbrush<>0 then DeleteObject(hbrush)
	if hbmp<>0 then DeleteObject(hbmp)
	if bmp_dc<>0 then DeleteDC(bmp_dc)
	if wnd_dc<>0 then ReleaseDC(pb_hwnd,wnd_dc)

end if

return ret

end function

private function unsignedlong f_and (unsignedlong a1, unsignedlong a2);int and_bits[32]
int i=32

do while a1>0 and a2>0
	if mod(a1,2)=1 and mod(a2,2)=1 then and_bits[i]=1
	a1=a1/2
	a2=a2/2
	i --
loop

unsignedlong res=0

for i=1 to 32
	res=res*2+and_bits[i]
next

return res

end function

public function boolean f_mapcolor (long dst_hdc, long w, long h, long color_from, long color_to);boolean ret=false

long		mono_hdc = 0
long		mono_bmp = 0
long		old_mono_bmp = 0
long		brush = 0
long		old_brush=0

mono_hdc = CreateCompatibleDC( 0 )
if mono_hdc = 0 then goto leave

mono_bmp = CreateBitmap( w, h, 1, 1, 0);
if mono_bmp =0 then goto leave

old_mono_bmp = SelectObject( mono_hdc, mono_bmp )

SetBkColor( mono_hdc, 16777215)//0x00FFFFFF
SetTextColor( mono_hdc, 0)

SetBkColor( dst_hdc, color_from )
SetTextColor( dst_hdc, 0 )

BitBlt( mono_hdc, 0, 0, w, h, dst_hdc, 0, 0, 13369376)//SRCCOPY=0x00CC0020

SetBkColor( dst_hdc, 16777215)//0x00FFFFFF

 // Create the pattern
brush = CreateSolidBrush( color_to );
if brush=0 then goto leave

old_brush = SelectObject( dst_hdc, brush )

// Convert using ( dest AND ( NOT source ) ) OR ( source AND pattern )
BitBlt( dst_hdc, 0, 0, w, h, mono_hdc, 0, 0,	14812998) // DSPDxax=0x00E20746
SelectObject( dst_hdc, old_brush );

ret = true

leave:
// Restore settings
if mono_hdc<>0 and old_mono_bmp<>0 then SelectObject( mono_hdc, old_mono_bmp )
if brush<>0 then DeleteObject( brush )
if mono_bmp<>0 then DeleteObject( mono_bmp )
if mono_hdc<>0 then DeleteDC( mono_hdc )

return ret

end function

on n_picture_masker.create
call super::create
TriggerEvent( this, "constructor" )
end on

on n_picture_masker.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

