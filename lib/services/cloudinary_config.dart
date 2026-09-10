/// Танзимоти Cloudinary — ҳамонест, ки барои imkon.estate истифода
/// шуда буд. Ду арзишро аз ҳисоби Cloudinary-и худ гузоред:
///
/// 1. cloudName — дар Cloudinary Dashboard, боло-рост (масалан "dxyz1234")
/// 2. uploadPreset — Settings → Upload → "Upload presets" → Add upload
///    preset → Signing Mode-ро ба "Unsigned" гузоред → номашро нигоҳ доред
///
/// Ин ду арзиш махфӣ нестанд (набояд бо секретҳо омехта шаванд) — вале
/// upload preset-и unsigned бояд танҳо барои иҷозати боркунии акс
/// танзим шуда бошад (на дигар амалиёт), то сӯиистифода нашавад.
class CloudinaryConfig {
  static const String cloudName = 'dstcdluhm';
  static const String uploadPreset = 'imkon_upload';
}
