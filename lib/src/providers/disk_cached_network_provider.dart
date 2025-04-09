import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../composition.dart';
import '../lottie_image_asset.dart';
import 'load_fonts.dart';
import 'load_image.dart';
import 'lottie_provider.dart';

@immutable
class DiskCachedNetworkLottie extends LottieProvider {
  DiskCachedNetworkLottie(
    this.url,
    this.bytes, {
    super.imageProviderFactory,
    super.decoder,
    super.backgroundLoading,
  });

  final String url;
  final Uint8List bytes;

  static Future<LottieComposition>? retrieveLoadedComposition(String url) {
    return sharedLottieCache.getIfContained(url.hashCode);
  }

  @override
  Future<LottieComposition> load({BuildContext? context}) {
    return sharedLottieCache.putIfAbsent(hashCode, () async {
      var resolved = Uri.base.resolve(url);

      LottieComposition composition;

      if (backgroundLoading) {
        composition = await compute(parseJsonBytes, (bytes, decoder));
      } else {
        composition =
            await LottieComposition.fromBytes(bytes, decoder: decoder);
      }

      for (var image in composition.images.values) {
        image.loadedImage ??= await _loadImage(resolved, composition, image);
      }

      await ensureLoadedFonts(composition);

      return composition;
    });
  }

  Future<ui.Image?> _loadImage(Uri jsonUri, LottieComposition composition,
      LottieImageAsset lottieImage) {
    var imageProvider = getImageProvider(lottieImage);

    if (imageProvider == null) {
      var imageUrl = jsonUri
          .resolve(p.url.join(lottieImage.dirName, lottieImage.fileName));
      imageProvider = NetworkImage(imageUrl.toString());
    }

    return loadImage(composition, lottieImage, imageProvider);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is DiskCachedNetworkLottie &&
        other.url == url &&
        other.decoder == decoder;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '$runtimeType(url: $url)';
}
