/// 为 github.com 资源按镜像优先级生成候选 URL 列表。
///
/// 国内直连 github.com 经常超时，需要先走镜像；若镜像故障再回落官方。
/// 客户端按顺序尝试，第一个成功的即用。
class GithubMirrorResolver {
  const GithubMirrorResolver._();

  static const String _githubOrigin = 'https://github.com';
  static const String _ghfastMirror = 'https://ghfast.top/https://github.com';

  /// 返回按优先级排序的候选 URL。
  ///
  /// 若 [originalUrl] 不是 github.com 资源，则原样返回单元素列表。
  static List<String> candidates(String originalUrl) {
    if (!originalUrl.startsWith(_githubOrigin)) {
      return [originalUrl];
    }
    final mirrored = originalUrl.replaceFirst(_githubOrigin, _ghfastMirror);
    return [mirrored, originalUrl];
  }
}
