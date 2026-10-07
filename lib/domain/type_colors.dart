import 'models.dart';

/// One accent colour (ARGB) per shelf. Shared by the app UI and the
/// home-screen widgets so a shelf looks the same in both places.
int typeColorValue(ItemType t) => switch (t) {
      ItemType.task => 0xFF5B4FD6,
      ItemType.read => 0xFF2F7BC9,
      ItemType.watch => 0xFFD64F6E,
      ItemType.wishlist => 0xFFD08A1E,
      ItemType.idea => 0xFFC9A400,
      ItemType.person => 0xFF2E9E8F,
      ItemType.capsule || ItemType.future => 0xFF7E57C2,
      ItemType.app => 0xFF3D8B5A,
      ItemType.podcast => 0xFFE0663C,
      ItemType.course => 0xFF3F6FD0,
      ItemType.game => 0xFF9B4FCF,
    };
