import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

enum MediaPickerPermission { notDetermined, authorized, limited, denied }

class MediaPickerState {
  final List<AssetEntity> assets;
  final MediaPickerPermission permission;
  final bool isLoading;
  final bool hasMore;
  final int _page;

  const MediaPickerState({
    this.assets = const [],
    this.permission = MediaPickerPermission.notDetermined,
    this.isLoading = false,
    this.hasMore = true,
    int page = 0,
  }) : _page = page;

  int get page => _page;

  MediaPickerState copyWith({
    List<AssetEntity>? assets,
    MediaPickerPermission? permission,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return MediaPickerState(
      assets: assets ?? this.assets,
      permission: permission ?? this.permission,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? _page,
    );
  }
}

class MediaPickerNotifier extends Notifier<MediaPickerState> {
  static const _pageSize = 50;
  AssetPathEntity? _recentAlbum;

  @override
  MediaPickerState build() {
    return const MediaPickerState();
  }

  Future<void> requestPermissionAndLoad() async {
    // Skip on desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      state = state.copyWith(permission: MediaPickerPermission.denied);
      return;
    }

    state = state.copyWith(isLoading: true);

    final result = await PhotoManager.requestPermissionExtend();

    switch (result) {
      case PermissionState.authorized:
        state = state.copyWith(permission: MediaPickerPermission.authorized);
      case PermissionState.limited:
        state = state.copyWith(permission: MediaPickerPermission.limited);
      case PermissionState.denied:
      case PermissionState.restricted:
        state = state.copyWith(
          permission: MediaPickerPermission.denied,
          isLoading: false,
        );
        return;
      case PermissionState.notDetermined:
        state = state.copyWith(
          permission: MediaPickerPermission.notDetermined,
          isLoading: false,
        );
        return;
    }

    await _loadInitialAssets();
  }

  Future<void> _loadInitialAssets() async {
    try {
      final filterOption = FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      );
      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.common,
        filterOption: filterOption,
      );

      if (paths.isEmpty) {
        state = state.copyWith(assets: [], isLoading: false, hasMore: false);
        return;
      }

      _recentAlbum = paths.first;
      final assets = await _recentAlbum!.getAssetListPaged(
        page: 0,
        size: _pageSize,
      );

      state = state.copyWith(
        assets: assets,
        isLoading: false,
        hasMore: assets.length >= _pageSize,
        page: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _recentAlbum == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final assets = await _recentAlbum!.getAssetListPaged(
        page: nextPage,
        size: _pageSize,
      );

      state = state.copyWith(
        assets: [...state.assets, ...assets],
        isLoading: false,
        hasMore: assets.length >= _pageSize,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    _recentAlbum = null;
    state = const MediaPickerState();
    await requestPermissionAndLoad();
  }
}

final mediaPickerProvider =
    NotifierProvider<MediaPickerNotifier, MediaPickerState>(
      () => MediaPickerNotifier(),
    );
