#ifndef __MV_INTER__
#define __MV_INTER__

#include "CopyCode.h"
#include "MVClip.h"
#include "MVFilter.h"
#include "SimpleResize.h"
#include "yuy2planes.h"
#include "overlap.h"

class MVGroupOfFrames;

/*! \brief Filter that change fps by blocks moving
 */
class MVBlockFps
  : public GenericVideoFilter
  , public MVFilter
{
private:

  MVClip mvClipB;
  MVClip mvClipF;
  unsigned int numerator;
  unsigned int denominator;
  unsigned int numeratorOld;
  unsigned int denominatorOld;
  int mode;
  double ml;
  PClip super;

  int cpuFlags;
  bool planar;
  bool blend;

  int64_t fa, fb;

  int nSuperModeYUV;

  BYTE *MaskFullYB; // shifted (projected) images planes
  BYTE *MaskFullUVB;
  BYTE *MaskFullYF;
  BYTE *MaskFullUVF;

  BYTE *MaskOccY; // full frame occlusion mask
  BYTE *MaskOccUV;

  BYTE *smallMaskF;// small forward occlusion mask
  BYTE *smallMaskB; // backward
  BYTE *smallMaskO; // both

  BYTE *TmpBlock; // block for temporary calculations
  int nBlkPitch;// padded (pitch)

  int nWidthP, nHeightP, nPitchY, nPitchUV, nHeightPUV, nWidthPUV, nHeightUV, nWidthUV;
  int nBlkXP, nBlkYP;

  COPYFunction *BLITLUMA;
  COPYFunction *BLITCHROMA;

  YUY2Planes * DstPlanes;

  bool is444;
  bool isGrey;
  bool isRGB; // avs+ planar
  //bool needDistinctChroma; buffer usage not yet optimized like in MFlowFPS
  int pixelsize_super;
  int bits_per_pixel_super;
  int pixelsize_super_shift;
  int planecount;
  int xRatioUVs[3];
  int yRatioUVs[3];
  int nLogxRatioUVs[3];
  int nLogyRatioUVs[3];

  int DestBufElementSize;

  short *winOver;
  short *winOverUV;

  OverlapWindows *OverWins;
  OverlapWindows *OverWinsUV;

  OverlapsFunction *OVERSLUMA;
  OverlapsFunction *OVERSCHROMA;
  OverlapsFunction *OVERSLUMA16; // 161115
  OverlapsFunction *OVERSCHROMA16; // 161115
  OverlapsFunction *OVERSLUMA32;
  OverlapsFunction *OVERSCHROMA32;
  uint16_t * DstShort;
  uint16_t * DstShortU;
  uint16_t * DstShortV;
  int dstShortPitch;
  int dstShortPitchUV;

  MVGroupOfFrames *pRefBGOF;
  MVGroupOfFrames *pRefFGOF;

  //	void MakeSmallMask(BYTE *image, int imagePitch, BYTE *smallmask, int nBlkX, int nBlkY, int nBlkSizeX, int nBlkSizeY, int threshold);
  //	void InflateMask(BYTE *smallmask, int nBlkX, int nBlkY);
  void MultMasks(BYTE *smallmaskF, BYTE *smallmaskB, BYTE *smallmaskO, int nBlkX, int nBlkY);
  template<typename pixel_t>
  void ResultBlock(BYTE *pDst8, int dst_pitch, const BYTE * pMCB8, int MCB_pitch, const BYTE * pMCF8, int MCF_pitch,
    const BYTE * pRef8, int ref_pitch, const BYTE * pSrc8, int src_pitch, BYTE *maskB, int mask_pitch, BYTE *maskF,
    BYTE *pOcc, int nBlkSizeX, int nBlkSizeY, int time256, int mode, int bits_per_pixel);

  SimpleResize *upsizer;
  SimpleResize *upsizerUV;

  int nSuperHPad, nSuperVPad;

public:
  MVBlockFps(
    PClip _child, PClip _super, PClip _mvbw, PClip _mvfw,
    unsigned int _num, unsigned int _den, int _mode, double _ml, bool _blend,
    sad_t nSCD1, int nSCD2, bool isse, bool _planar, bool mt_flag,
    IScriptEnvironment* env
  );
  ~MVBlockFps();
  PVideoFrame __stdcall GetFrame(int n, IScriptEnvironment* env) override;

  int __stdcall SetCacheHints(int cachehints, int frame_range) override {
    return cachehints == CACHE_GET_MTMODE ? MT_MULTI_INSTANCE : 0;
  }

};

#endif
