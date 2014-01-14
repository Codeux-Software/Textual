/*********************************************************************************/
/*                                                                               */
/* nameprep_lookups.h                                                            */
/*                                                                               */
/* Nameprep data table lookup routines.                                          */
/*                                                                               */
/* (c) Verisign Inc., 2000-2003, All rights reserved                             */
/*                                                                               */
/*********************************************************************************/

#include "nameprep_data.h"

#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */

/*********************************************************************************
*
* static int lookup_charmap( DWORD dwChar, const DWORD ** ppdwBlock )
* 
*  Applies character mapping to a codepoint. Returns length of mapped string 
*  in pdwzChar or 0 if the codepoint was not mapped. If the character is mapped,
*  pdwzChar returns a const pointer into the static data table.
*
**********************************************************************************/

static int lookup_charmap( DWORD dwChar, const DWORD ** ppdwBlock )
{
  int high, low;

  /* { index: 0x00000041, len, c1->c4: 1, 0x00000061,0x00000000,0x00000000,0x00000000 }, */

  if ( ppdwBlock == 0 ) return 0;

  *ppdwBlock = 0;

  low   = -1;
  high  = CHARMAP_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( dwChar <= g_charmapTable[ii].dwCodepoint )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( dwChar == g_charmapTable[high].dwCodepoint )
  {
    *ppdwBlock = &g_charmapTable[high].dwzData[0];
    return g_charmapTable[high].length;
  }

  return -1;
}

/*********************************************************************************
*
* static int lookup_prohbited( DWORD dwCodepoint )
* 
*  Determines if a single codepoint is prohibited by Nameprep. Returns 0 if 
*  not found, 1 if found.
*
**********************************************************************************/

static int lookup_prohbited( DWORD dwCodepoint ) 
{
  int ii;

  for ( ii = 0; ii <= PROHIBIT_ENTRYCOUNT; ii++ )
  {
    if ( dwCodepoint > g_prohibitTable[ii].high ) continue;
    if ( dwCodepoint >= g_prohibitTable[ii].low && dwCodepoint <= g_prohibitTable[ii].high ) return 1;
  }

  return 0;
}

/*********************************************************************************
*
* static int lookup_bidi_randalcat( DWORD dwCodepoint )
* 
*  Returns 1 if the character is RandALCat, 0 if not.
*
**********************************************************************************/

static int lookup_bidi_randalcat( DWORD dwCodepoint )
{
  int high, low;

  if ( dwCodepoint == 0 ) return 0;

  low   = -1;
  high  = RANDALCAT_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( dwCodepoint <= g_randalcatTable[ii] )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( dwCodepoint == g_randalcatTable[high] )
  {
    return 1;
  }

  return 0;
}

/*********************************************************************************
*
* static int lookup_bidi_lcat( DWORD dwCodepoint )
* 
*  Returns 1 if the character is LCat, 0 if not.
*
**********************************************************************************/

static int lookup_bidi_lcat( DWORD dwCodepoint )
{
  int ii;

  for ( ii = 0; ii <= LCAT_ENTRYCOUNT; ii++ )
  {
    if ( dwCodepoint > g_lcatTable[ii].high ) continue;
    if ( dwCodepoint >= g_lcatTable[ii].low && dwCodepoint <= g_lcatTable[ii].high ) return 1;
  }

  return 0;
}

/*********************************************************************************
*
* static int lookup_decompose( DWORD dwChar, const DWORD ** pdwzChar )
* 
*  Applies decomposition to a codepoint. Returns length of mapped string 
*  in pdwzChar or 0 if the codepoint was not mapped. If the character is mapped,
*  pdwzChar returns a const pointer into the static data table.
*
**********************************************************************************/

static int lookup_decompose( DWORD dwChar, const DWORD ** pdwzChar )
{
  int high, low;

  if ( pdwzChar == 0 ) return 0;

  *pdwzChar = 0;

  low   = -1;
  high  = DECOMPOSE_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( dwChar <= g_decomposeTable[ii].dwCodepoint )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( dwChar == g_decomposeTable[high].dwCodepoint )
  {
    *pdwzChar = g_decomposeTable[high].dwzData;
    return g_decomposeTable[high].length;
  }

  return 0;
}


/*********************************************************************************
*
* static int lookup_composite( QWORD qwPair, DWORD * dwCodepoint )
* 
*  Applies composition to a codepoint pair. Returns the appropriate codepoint
*  in dwCodepoint or 0 if the codepoint was not mapped.
*
**********************************************************************************/

static int lookup_composite( QWORD qwPair, DWORD * dwCodepoint )
{
  int high, low;

  if ( dwCodepoint == 0 ) return 0;

  low   = -1;
  high  = COMPOSE_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( qwPair <= g_composeTable[ii].qwPair )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( qwPair == g_composeTable[high].qwPair )
  {
    *dwCodepoint = g_composeTable[high].dwCodepoint;
    return 1;
  }

  return 0;
}


/*********************************************************************************
*
* static DWORD lookup_canonical( DWORD dwCodepoint )
* 
*  Returns a codepoint's canonical class or 0 if not found.
*
**********************************************************************************/

static DWORD lookup_canonical( DWORD dwCodepoint )
{
  int high, low;

  if ( dwCodepoint == 0 ) return 0;

  low   = -1;
  high  = CANONICAL_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( dwCodepoint <= g_canonicalTable[ii].dwCodepoint )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( dwCodepoint == g_canonicalTable[high].dwCodepoint )
  {
    return g_canonicalTable[high].dwClass;
  }

  return 0;
}


/*********************************************************************************
*
* static int lookup_compatible( DWORD dwCodepoint )
* 
*  Determines if a codepoint is compatible. Returns 1 or 0.
*
**********************************************************************************/

static int lookup_compatible( DWORD dwCodepoint )
{
  int high, low;

  low   = -1;
  high  = COMPATIBLE_ENTRYCOUNT;

  while ( high - low > 1 )
  {
    int ii = ( high + low ) / 2;

    if ( dwCodepoint <= g_compatibleTable[ii] )
    {
      high = ii;
    } else {
      low  = ii;
    }
  }

  if ( dwCodepoint == g_compatibleTable[high] )
  {
    return 1;
  }

  return 0;
}

#ifdef __cplusplus
}
#endif /* __cplusplus */
