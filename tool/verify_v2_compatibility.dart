import 'dart:convert';
import 'dart:io';

import 'package:howtocook/features/recipe/domain/entities/recipe.dart';
import 'package:howtocook/features/sync/domain/entities/manifest.dart';

/// 验证一个已生成的 HowToCook V2 版本能否被当前 Flutter 模型完整读取。
///
/// 用法：
/// dart run tool/verify_v2_compatibility.dart path/to/version-directory
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/verify_v2_compatibility.dart '
      '<version-directory>',
    );
    exitCode = 64;
    return;
  }

  final versionDirectory = Directory(arguments.single);
  final manifestFile = File('${versionDirectory.path}/manifest.json');
  if (!await manifestFile.exists()) {
    stderr.writeln('Manifest not found: ${manifestFile.path}');
    exitCode = 66;
    return;
  }

  final manifestJson =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final manifest = Manifest.fromJson(manifestJson);
  if (manifest.schemaVersion != 2) {
    throw FormatException(
      'Expected schemaVersion 2, got ${manifest.schemaVersion}',
    );
  }

  var parsedImages = 0;
  var legacyIds = 0;
  for (final index in manifest.recipes) {
    final recipeFile = File(
      '${versionDirectory.path}/recipes/${index.category}/${index.id}.json',
    );
    final recipeJson =
        jsonDecode(await recipeFile.readAsString()) as Map<String, dynamic>;
    final recipe = Recipe.fromJson(recipeJson);
    if (recipe.id != index.id || recipe.category != index.category) {
      throw FormatException('Manifest mismatch: ${recipeFile.path}');
    }
    parsedImages += recipe.images.length;
    legacyIds += recipe.legacyIds.length;
  }

  stdout.writeln(
    'V2 compatibility passed: version=${manifest.version}, '
    'recipes=${manifest.recipes.length}, images=$parsedImages, '
    'legacyIds=$legacyIds',
  );
}
