/*********************************************************************
 *                               G P S                               *
 *                                                                   *
 *                      Copyright (C) 2002-2005                      *
 *                            ACT-Europe                             *
 *                                                                   *
 * GPS is free  software;  you can redistribute it and/or modify  it *
 * under the terms of the GNU General Public License as published by *
 * the Free Software Foundation; either version 2 of the License, or *
 * (at your option) any later version.                               *
 *                                                                   *
 * This program is  distributed in the hope that it will be  useful, *
 * but  WITHOUT ANY WARRANTY;  without even the  implied warranty of *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU *
 * General Public License for more details. You should have received *
 * a copy of the GNU General Public License along with this program; *
 * if not,  write to the  Free Software Foundation, Inc.,  59 Temple *
 * Place - Suite 330, Boston, MA 02111-1307, USA.                    *
 *********************************************************************/

/*
 * Native file selection dialogs
 */

#ifdef _WIN32

#include <windows.h>
#include <commdlg.h>
#include <stdlib.h>
#include <stdio.h>

/*
 * NativeFileSelection
 *
 * open a common file open dialog
 *
 * return the selected file
 * user shall free the result
 */

static int
FileSelectionHook
  (HWND   hdlg,
   UINT   uiMsg,
   WPARAM wParam,
   LPARAM lParam)
{
  POINT* lpPos;
  RECT   rect;

  switch (uiMsg)
    {
      case WM_INITDIALOG:
        /* move the window to the proper position */

        lpPos = (POINT*) (((OPENFILENAME*) lParam)->lCustData);
        SetWindowPos (GetParent (hdlg), HWND_TOP,
                      lpPos->x,
                      lpPos->y,
                      0, 0, SWP_NOSIZE);
        return 0;
	break;

      default:
	break;
    }

  return 0;
}

static char*
NativeWin32FileSelection
  (const char*  title,
   const char*  basedir,
   const char*  filepattern,
   const char*  patternname,
   const char*  defaultname,
   int          style,
   int          kind)
{
  static OPENFILENAME ofn;
  static char         l_Filter [512];
  static char         l_Result [MAX_PATH];
  int                 l_index = 0;
  char*               res;
  BOOL                ret;

  static POINT        position;
  RECT                aw_rect;
  unsigned int        style_flag;
  HWND                active_window = GetActiveWindow ();

  switch (style)
    {
      case 2:
        /* position under mouse */

        GetCursorPos (&position);
        style_flag = OFN_ENABLEHOOK;
        break;

      case 1:
        /* position center of the active window */

        if (active_window)
          {
            GetWindowRect (active_window, &aw_rect);
            position.x = (aw_rect.left + aw_rect.right) / 2;
            position.y = (aw_rect.top + aw_rect.bottom) / 2;
            style_flag = OFN_ENABLEHOOK;
            break;
          }

        /* otherwise, default case */

      case 0:
      default:
        /* default position */

        style_flag = 0;
        break ;
    }

  if (patternname != 0)
    {
      strcpy (l_Filter, patternname);
      l_index += strlen (patternname) + 1;
    }

  if (filepattern != 0)
    {
      strcpy (l_Filter + l_index, filepattern);
      l_index += strlen (filepattern) + 1;
      l_Filter [l_index] = '\0';
    }

  if (defaultname)
    strcpy (l_Result, defaultname);
  else
    l_Result [0] = '\0';

  ofn.lStructSize       = sizeof (OPENFILENAME);
  ofn.hwndOwner         = active_window;
  ofn.hInstance         = NULL;
  ofn.lpstrFilter       = l_Filter;
  ofn.lpstrCustomFilter = NULL;
  ofn.nMaxCustFilter    = 0;
  ofn.nFilterIndex      = 0;
  ofn.lpstrFile         = l_Result;
  ofn.nMaxFile          = MAX_PATH;
  ofn.lpstrFileTitle    = NULL;
  ofn.nMaxFileTitle     = 0;
  ofn.lpstrInitialDir   = basedir;
  ofn.lpstrTitle        = title;

  if (kind == 1)
    ofn.Flags = OFN_HIDEREADONLY | OFN_EXPLORER | style_flag;
  else
    /* ??? Would be nice to take advantage of READONLY and CREATEPROMPT */
    ofn.Flags = OFN_HIDEREADONLY | OFN_EXPLORER | style_flag;

  ofn.nFileOffset       = 0;
  ofn.nFileExtension    = 0;
  ofn.lpstrDefExt       = "";
  ofn.lCustData         = (LPARAM) &position;
  ofn.lpfnHook          = (LPOFNHOOKPROC) FileSelectionHook;
  ofn.lpTemplateName    = NULL;

  if (kind == 1)
    ret = GetSaveFileName (&ofn);
  else
    ret = GetOpenFileName (&ofn);

  if (!ret)
    l_Result [0] = '\0';

  /* copy the result into a well sized string */

  res = malloc (sizeof (char) * (strlen (l_Result) + 1));
  strcpy (res, l_Result);
  return res;
}

/*
 * style:
 *    0 : nothing
 *    1 : center
 *    2 : under mouse
 *
 * kind:
 *    0 : open
 *    1 : save
 *    2 : unspecified
 */

char*
NativeFileSelection
  (const char*  title,
   const char*  basedir,
   const char*  filepattern,
   const char*  patternname,
   const char*  defaultname,
   int          style,
   int          kind)
{
  return NativeWin32FileSelection
    (title, basedir, filepattern, patternname, defaultname, 0, kind);
}

int
NativeFileSelectionSupported ()
{
  return 1;
}

#else

char*
NativeFileSelection
  (const char*  title,
   const char*  basedir,
   const char*  filepattern,
   const char*  patternname,
   const char*  defaultname,
   int          style,
   int          kind)
{
  return (char *)0;
}

int
NativeFileSelectionSupported ()
{
  return 0;
}

#endif
