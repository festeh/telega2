import 'package:telega2/domain/entities/emoji.dart';

/// Static emoji data - codepoints, names, categories
/// This provides the full emoji catalog for the picker
class EmojiData {
  static final EmojiData _instance = EmojiData._internal();
  factory EmojiData() => _instance;
  EmojiData._internal();

  /// All emojis indexed by codepoint
  final Map<String, Emoji> _emojisByCodepoint = {};

  /// Emojis grouped by category
  final Map<EmojiCategory, List<Emoji>> _emojisByCategory = {};

  /// Initialize emoji data - call once at app startup
  void initialize() {
    if (_emojisByCodepoint.isNotEmpty) return;

    for (final data in _rawEmojiData) {
      final emoji = Emoji(
        codepoint: data['codepoint'] as String,
        name: data['name'] as String,
        category: data['category'] as EmojiCategory,
        shortcodes: (data['shortcodes'] as List<String>?) ?? [],
        skinToneSupport: data['skinTone'] as bool? ?? false,
        hasAnimation: data['animated'] as bool? ?? false,
      );

      _emojisByCodepoint[emoji.codepoint] = emoji;
      _emojisByCategory.putIfAbsent(emoji.category, () => []).add(emoji);
    }
  }

  /// Get emoji by codepoint
  Emoji? getEmoji(String codepoint) => _emojisByCodepoint[codepoint];

  /// Get emoji by character (unicode string)
  Emoji? getEmojiByChar(String char) {
    // Convert character to codepoint
    final codepoint = char.runes
        .map((r) => r.toRadixString(16).toUpperCase())
        .join('-');
    return _emojisByCodepoint[codepoint];
  }

  /// Get all emojis in a category
  List<Emoji> getEmojisByCategory(EmojiCategory category) =>
      _emojisByCategory[category] ?? [];

  /// Search emojis by name or shortcode
  List<Emoji> searchEmojis(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final results = <Emoji>[];

    for (final emoji in _emojisByCodepoint.values) {
      if (emoji.name.toLowerCase().contains(lowerQuery)) {
        results.add(emoji);
        continue;
      }
      for (final shortcode in emoji.shortcodes) {
        if (shortcode.toLowerCase().contains(lowerQuery)) {
          results.add(emoji);
          break;
        }
      }
    }

    // Sort by relevance (exact match first, then starts with, then contains)
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      if (aName == lowerQuery && bName != lowerQuery) return -1;
      if (bName == lowerQuery && aName != lowerQuery) return 1;
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) {
        return -1;
      }
      if (bName.startsWith(lowerQuery) && !aName.startsWith(lowerQuery)) {
        return 1;
      }
      return aName.compareTo(bName);
    });

    return results.take(50).toList();
  }

  /// Get all emojis
  List<Emoji> get allEmojis => _emojisByCodepoint.values.toList();

  /// Get all categories with their emojis
  Map<EmojiCategory, List<Emoji>> get emojisByCategory => _emojisByCategory;

  /// Raw emoji data - subset of common emojis
  /// Full dataset would be loaded from bundled JSON in production
  static final List<Map<String, dynamic>> _rawEmojiData = [
    // Smileys & Emotion
    {
      'codepoint': '1F600',
      'name': 'grinning face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':grinning:', ':grin:'],
      'animated': true,
    },
    {
      'codepoint': '1F603',
      'name': 'grinning face with big eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smiley:'],
      'animated': true,
    },
    {
      'codepoint': '1F604',
      'name': 'grinning face with smiling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smile:'],
      'animated': true,
    },
    {
      'codepoint': '1F601',
      'name': 'beaming face with smiling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':grin:'],
      'animated': true,
    },
    {
      'codepoint': '1F606',
      'name': 'grinning squinting face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':laughing:'],
      'animated': true,
    },
    {
      'codepoint': '1F605',
      'name': 'grinning face with sweat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sweat_smile:'],
      'animated': true,
    },
    {
      'codepoint': '1F923',
      'name': 'rolling on the floor laughing',
      'category': EmojiCategory.smileys,
      'shortcodes': [':rofl:'],
      'animated': true,
    },
    {
      'codepoint': '1F602',
      'name': 'face with tears of joy',
      'category': EmojiCategory.smileys,
      'shortcodes': [':joy:'],
      'animated': true,
    },
    {
      'codepoint': '1F642',
      'name': 'slightly smiling face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':slight_smile:'],
    },
    {
      'codepoint': '1F643',
      'name': 'upside-down face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':upside_down:'],
    },
    {
      'codepoint': '1F609',
      'name': 'winking face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':wink:'],
      'animated': true,
    },
    {
      'codepoint': '1F60A',
      'name': 'smiling face with smiling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':blush:'],
      'animated': true,
    },
    {
      'codepoint': '1F607',
      'name': 'smiling face with halo',
      'category': EmojiCategory.smileys,
      'shortcodes': [':innocent:'],
    },
    {
      'codepoint': '1F970',
      'name': 'smiling face with hearts',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smiling_face_with_hearts:'],
      'animated': true,
    },
    {
      'codepoint': '1F60D',
      'name': 'smiling face with heart-eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':heart_eyes:'],
      'animated': true,
    },
    {
      'codepoint': '1F929',
      'name': 'star-struck',
      'category': EmojiCategory.smileys,
      'shortcodes': [':star_struck:'],
      'animated': true,
    },
    {
      'codepoint': '1F618',
      'name': 'face blowing a kiss',
      'category': EmojiCategory.smileys,
      'shortcodes': [':kissing_heart:'],
      'animated': true,
    },
    {
      'codepoint': '1F617',
      'name': 'kissing face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':kissing:'],
    },
    {
      'codepoint': '1F61A',
      'name': 'kissing face with closed eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':kissing_closed_eyes:'],
    },
    {
      'codepoint': '1F619',
      'name': 'kissing face with smiling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':kissing_smiling_eyes:'],
    },
    {
      'codepoint': '1F60B',
      'name': 'face savoring food',
      'category': EmojiCategory.smileys,
      'shortcodes': [':yum:'],
    },
    {
      'codepoint': '1F61B',
      'name': 'face with tongue',
      'category': EmojiCategory.smileys,
      'shortcodes': [':stuck_out_tongue:'],
    },
    {
      'codepoint': '1F61C',
      'name': 'winking face with tongue',
      'category': EmojiCategory.smileys,
      'shortcodes': [':stuck_out_tongue_winking_eye:'],
      'animated': true,
    },
    {
      'codepoint': '1F92A',
      'name': 'zany face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':zany_face:'],
    },
    {
      'codepoint': '1F61D',
      'name': 'squinting face with tongue',
      'category': EmojiCategory.smileys,
      'shortcodes': [':stuck_out_tongue_closed_eyes:'],
    },
    {
      'codepoint': '1F911',
      'name': 'money-mouth face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':money_mouth:'],
    },
    {
      'codepoint': '1F917',
      'name': 'hugging face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':hugs:'],
    },
    {
      'codepoint': '1F92D',
      'name': 'face with hand over mouth',
      'category': EmojiCategory.smileys,
      'shortcodes': [':hand_over_mouth:'],
    },
    {
      'codepoint': '1F92B',
      'name': 'shushing face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':shushing:'],
    },
    {
      'codepoint': '1F914',
      'name': 'thinking face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':thinking:'],
    },
    {
      'codepoint': '1F910',
      'name': 'zipper-mouth face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':zipper_mouth:'],
    },
    {
      'codepoint': '1F928',
      'name': 'face with raised eyebrow',
      'category': EmojiCategory.smileys,
      'shortcodes': [':raised_eyebrow:'],
    },
    {
      'codepoint': '1F610',
      'name': 'neutral face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':neutral_face:'],
    },
    {
      'codepoint': '1F611',
      'name': 'expressionless face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':expressionless:'],
    },
    {
      'codepoint': '1F636',
      'name': 'face without mouth',
      'category': EmojiCategory.smileys,
      'shortcodes': [':no_mouth:'],
    },
    {
      'codepoint': '1F60F',
      'name': 'smirking face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smirk:'],
    },
    {
      'codepoint': '1F612',
      'name': 'unamused face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':unamused:'],
    },
    {
      'codepoint': '1F644',
      'name': 'face with rolling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':roll_eyes:'],
    },
    {
      'codepoint': '1F62C',
      'name': 'grimacing face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':grimacing:'],
    },
    {
      'codepoint': '1F62E-200D-1F4A8',
      'name': 'face exhaling',
      'category': EmojiCategory.smileys,
      'shortcodes': [':exhale:'],
    },
    {
      'codepoint': '1F925',
      'name': 'lying face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':lying_face:'],
    },
    {
      'codepoint': '1F60C',
      'name': 'relieved face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':relieved:'],
    },
    {
      'codepoint': '1F614',
      'name': 'pensive face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':pensive:'],
    },
    {
      'codepoint': '1F62A',
      'name': 'sleepy face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sleepy:'],
    },
    {
      'codepoint': '1F924',
      'name': 'drooling face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':drooling:'],
    },
    {
      'codepoint': '1F634',
      'name': 'sleeping face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sleeping:'],
    },
    {
      'codepoint': '1F637',
      'name': 'face with medical mask',
      'category': EmojiCategory.smileys,
      'shortcodes': [':mask:'],
    },
    {
      'codepoint': '1F912',
      'name': 'face with thermometer',
      'category': EmojiCategory.smileys,
      'shortcodes': [':thermometer_face:'],
    },
    {
      'codepoint': '1F915',
      'name': 'face with head-bandage',
      'category': EmojiCategory.smileys,
      'shortcodes': [':bandage_face:'],
    },
    {
      'codepoint': '1F922',
      'name': 'nauseated face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':nauseated:'],
    },
    {
      'codepoint': '1F92E',
      'name': 'face vomiting',
      'category': EmojiCategory.smileys,
      'shortcodes': [':vomiting:'],
    },
    {
      'codepoint': '1F927',
      'name': 'sneezing face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sneezing:'],
    },
    {
      'codepoint': '1F975',
      'name': 'hot face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':hot_face:'],
    },
    {
      'codepoint': '1F976',
      'name': 'cold face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':cold_face:'],
    },
    {
      'codepoint': '1F974',
      'name': 'woozy face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':woozy:'],
    },
    {
      'codepoint': '1F635',
      'name': 'face with crossed-out eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':dizzy_face:'],
    },
    {
      'codepoint': '1F92F',
      'name': 'exploding head',
      'category': EmojiCategory.smileys,
      'shortcodes': [':exploding_head:'],
      'animated': true,
    },
    {
      'codepoint': '1F920',
      'name': 'cowboy hat face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':cowboy:'],
    },
    {
      'codepoint': '1F973',
      'name': 'partying face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':partying:'],
      'animated': true,
    },
    {
      'codepoint': '1F978',
      'name': 'disguised face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':disguised:'],
    },
    {
      'codepoint': '1F60E',
      'name': 'smiling face with sunglasses',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sunglasses:'],
    },
    {
      'codepoint': '1F913',
      'name': 'nerd face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':nerd:'],
    },
    {
      'codepoint': '1F9D0',
      'name': 'face with monocle',
      'category': EmojiCategory.smileys,
      'shortcodes': [':monocle:'],
    },
    {
      'codepoint': '1F615',
      'name': 'confused face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':confused:'],
    },
    {
      'codepoint': '1F61F',
      'name': 'worried face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':worried:'],
    },
    {
      'codepoint': '1F641',
      'name': 'slightly frowning face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':slight_frown:'],
    },
    {
      'codepoint': '1F62E',
      'name': 'face with open mouth',
      'category': EmojiCategory.smileys,
      'shortcodes': [':open_mouth:'],
    },
    {
      'codepoint': '1F62F',
      'name': 'hushed face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':hushed:'],
    },
    {
      'codepoint': '1F632',
      'name': 'astonished face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':astonished:'],
    },
    {
      'codepoint': '1F633',
      'name': 'flushed face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':flushed:'],
    },
    {
      'codepoint': '1F97A',
      'name': 'pleading face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':pleading:'],
    },
    {
      'codepoint': '1F626',
      'name': 'frowning face with open mouth',
      'category': EmojiCategory.smileys,
      'shortcodes': [':frowning:'],
    },
    {
      'codepoint': '1F627',
      'name': 'anguished face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':anguished:'],
    },
    {
      'codepoint': '1F628',
      'name': 'fearful face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':fearful:'],
    },
    {
      'codepoint': '1F630',
      'name': 'anxious face with sweat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':cold_sweat:'],
    },
    {
      'codepoint': '1F625',
      'name': 'sad but relieved face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sad_relieved:'],
    },
    {
      'codepoint': '1F622',
      'name': 'crying face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':cry:'],
      'animated': true,
    },
    {
      'codepoint': '1F62D',
      'name': 'loudly crying face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sob:'],
      'animated': true,
    },
    {
      'codepoint': '1F631',
      'name': 'face screaming in fear',
      'category': EmojiCategory.smileys,
      'shortcodes': [':scream:'],
    },
    {
      'codepoint': '1F616',
      'name': 'confounded face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':confounded:'],
    },
    {
      'codepoint': '1F623',
      'name': 'persevering face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':persevere:'],
    },
    {
      'codepoint': '1F61E',
      'name': 'disappointed face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':disappointed:'],
    },
    {
      'codepoint': '1F613',
      'name': 'downcast face with sweat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':sweat:'],
    },
    {
      'codepoint': '1F629',
      'name': 'weary face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':weary:'],
    },
    {
      'codepoint': '1F62B',
      'name': 'tired face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':tired_face:'],
    },
    {
      'codepoint': '1F971',
      'name': 'yawning face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':yawning:'],
    },
    {
      'codepoint': '1F624',
      'name': 'face with steam from nose',
      'category': EmojiCategory.smileys,
      'shortcodes': [':triumph:'],
    },
    {
      'codepoint': '1F621',
      'name': 'pouting face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':rage:', ':pout:'],
    },
    {
      'codepoint': '1F620',
      'name': 'angry face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':angry:'],
    },
    {
      'codepoint': '1F92C',
      'name': 'face with symbols on mouth',
      'category': EmojiCategory.smileys,
      'shortcodes': [':cursing:'],
    },
    {
      'codepoint': '1F608',
      'name': 'smiling face with horns',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smiling_imp:'],
    },
    {
      'codepoint': '1F47F',
      'name': 'angry face with horns',
      'category': EmojiCategory.smileys,
      'shortcodes': [':imp:'],
    },
    {
      'codepoint': '1F480',
      'name': 'skull',
      'category': EmojiCategory.smileys,
      'shortcodes': [':skull:'],
    },
    {
      'codepoint': '1F4A9',
      'name': 'pile of poo',
      'category': EmojiCategory.smileys,
      'shortcodes': [':poop:', ':hankey:'],
    },
    {
      'codepoint': '1F921',
      'name': 'clown face',
      'category': EmojiCategory.smileys,
      'shortcodes': [':clown:'],
    },
    {
      'codepoint': '1F47B',
      'name': 'ghost',
      'category': EmojiCategory.smileys,
      'shortcodes': [':ghost:'],
    },
    {
      'codepoint': '1F47D',
      'name': 'alien',
      'category': EmojiCategory.smileys,
      'shortcodes': [':alien:'],
    },
    {
      'codepoint': '1F916',
      'name': 'robot',
      'category': EmojiCategory.smileys,
      'shortcodes': [':robot:'],
    },
    {
      'codepoint': '1F63A',
      'name': 'grinning cat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smiley_cat:'],
    },
    {
      'codepoint': '1F638',
      'name': 'grinning cat with smiling eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smile_cat:'],
    },
    {
      'codepoint': '1F639',
      'name': 'cat with tears of joy',
      'category': EmojiCategory.smileys,
      'shortcodes': [':joy_cat:'],
    },
    {
      'codepoint': '1F63B',
      'name': 'smiling cat with heart-eyes',
      'category': EmojiCategory.smileys,
      'shortcodes': [':heart_eyes_cat:'],
    },
    {
      'codepoint': '1F63C',
      'name': 'cat with wry smile',
      'category': EmojiCategory.smileys,
      'shortcodes': [':smirk_cat:'],
    },
    {
      'codepoint': '1F63D',
      'name': 'kissing cat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':kissing_cat:'],
    },
    {
      'codepoint': '1F640',
      'name': 'weary cat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':scream_cat:'],
    },
    {
      'codepoint': '1F63F',
      'name': 'crying cat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':crying_cat_face:'],
    },
    {
      'codepoint': '1F63E',
      'name': 'pouting cat',
      'category': EmojiCategory.smileys,
      'shortcodes': [':pouting_cat:'],
    },

    // People & Body - Hands
    {
      'codepoint': '1F44B',
      'name': 'waving hand',
      'category': EmojiCategory.people,
      'shortcodes': [':wave:'],
      'skinTone': true,
      'animated': true,
    },
    {
      'codepoint': '1F91A',
      'name': 'raised back of hand',
      'category': EmojiCategory.people,
      'shortcodes': [':raised_back_of_hand:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F590-FE0F',
      'name': 'hand with fingers splayed',
      'category': EmojiCategory.people,
      'shortcodes': [':hand_splayed:'],
      'skinTone': true,
    },
    {
      'codepoint': '270B',
      'name': 'raised hand',
      'category': EmojiCategory.people,
      'shortcodes': [':raised_hand:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F596',
      'name': 'vulcan salute',
      'category': EmojiCategory.people,
      'shortcodes': [':vulcan:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F44C',
      'name': 'OK hand',
      'category': EmojiCategory.people,
      'shortcodes': [':ok_hand:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F90C',
      'name': 'pinched fingers',
      'category': EmojiCategory.people,
      'shortcodes': [':pinched_fingers:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F90F',
      'name': 'pinching hand',
      'category': EmojiCategory.people,
      'shortcodes': [':pinching_hand:'],
      'skinTone': true,
    },
    {
      'codepoint': '270C-FE0F',
      'name': 'victory hand',
      'category': EmojiCategory.people,
      'shortcodes': [':v:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F91E',
      'name': 'crossed fingers',
      'category': EmojiCategory.people,
      'shortcodes': [':crossed_fingers:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F91F',
      'name': 'love-you gesture',
      'category': EmojiCategory.people,
      'shortcodes': [':love_you_gesture:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F918',
      'name': 'sign of the horns',
      'category': EmojiCategory.people,
      'shortcodes': [':metal:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F919',
      'name': 'call me hand',
      'category': EmojiCategory.people,
      'shortcodes': [':call_me:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F448',
      'name': 'backhand index pointing left',
      'category': EmojiCategory.people,
      'shortcodes': [':point_left:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F449',
      'name': 'backhand index pointing right',
      'category': EmojiCategory.people,
      'shortcodes': [':point_right:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F446',
      'name': 'backhand index pointing up',
      'category': EmojiCategory.people,
      'shortcodes': [':point_up_2:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F595',
      'name': 'middle finger',
      'category': EmojiCategory.people,
      'shortcodes': [':middle_finger:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F447',
      'name': 'backhand index pointing down',
      'category': EmojiCategory.people,
      'shortcodes': [':point_down:'],
      'skinTone': true,
    },
    {
      'codepoint': '261D-FE0F',
      'name': 'index pointing up',
      'category': EmojiCategory.people,
      'shortcodes': [':point_up:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F44D',
      'name': 'thumbs up',
      'category': EmojiCategory.people,
      'shortcodes': [':thumbsup:', ':+1:'],
      'skinTone': true,
      'animated': true,
    },
    {
      'codepoint': '1F44E',
      'name': 'thumbs down',
      'category': EmojiCategory.people,
      'shortcodes': [':thumbsdown:', ':-1:'],
      'skinTone': true,
    },
    {
      'codepoint': '270A',
      'name': 'raised fist',
      'category': EmojiCategory.people,
      'shortcodes': [':fist:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F44A',
      'name': 'oncoming fist',
      'category': EmojiCategory.people,
      'shortcodes': [':punch:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F91B',
      'name': 'left-facing fist',
      'category': EmojiCategory.people,
      'shortcodes': [':left_fist:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F91C',
      'name': 'right-facing fist',
      'category': EmojiCategory.people,
      'shortcodes': [':right_fist:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F44F',
      'name': 'clapping hands',
      'category': EmojiCategory.people,
      'shortcodes': [':clap:'],
      'skinTone': true,
      'animated': true,
    },
    {
      'codepoint': '1F64C',
      'name': 'raising hands',
      'category': EmojiCategory.people,
      'shortcodes': [':raised_hands:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F450',
      'name': 'open hands',
      'category': EmojiCategory.people,
      'shortcodes': [':open_hands:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F932',
      'name': 'palms up together',
      'category': EmojiCategory.people,
      'shortcodes': [':palms_up:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F91D',
      'name': 'handshake',
      'category': EmojiCategory.people,
      'shortcodes': [':handshake:'],
      'skinTone': true,
    },
    {
      'codepoint': '1F64F',
      'name': 'folded hands',
      'category': EmojiCategory.people,
      'shortcodes': [':pray:'],
      'skinTone': true,
      'animated': true,
    },

    // Symbols - Hearts
    {
      'codepoint': '2764-FE0F',
      'name': 'red heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':heart:'],
      'animated': true,
    },
    {
      'codepoint': '1F9E1',
      'name': 'orange heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':orange_heart:'],
    },
    {
      'codepoint': '1F49B',
      'name': 'yellow heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':yellow_heart:'],
    },
    {
      'codepoint': '1F49A',
      'name': 'green heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':green_heart:'],
    },
    {
      'codepoint': '1F499',
      'name': 'blue heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':blue_heart:'],
    },
    {
      'codepoint': '1F49C',
      'name': 'purple heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':purple_heart:'],
    },
    {
      'codepoint': '1F90E',
      'name': 'brown heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':brown_heart:'],
    },
    {
      'codepoint': '1F5A4',
      'name': 'black heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':black_heart:'],
    },
    {
      'codepoint': '1F90D',
      'name': 'white heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':white_heart:'],
    },
    {
      'codepoint': '1F494',
      'name': 'broken heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':broken_heart:'],
      'animated': true,
    },
    {
      'codepoint': '1F495',
      'name': 'two hearts',
      'category': EmojiCategory.symbols,
      'shortcodes': [':two_hearts:'],
    },
    {
      'codepoint': '1F496',
      'name': 'sparkling heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':sparkling_heart:'],
    },
    {
      'codepoint': '1F497',
      'name': 'growing heart',
      'category': EmojiCategory.symbols,
      'shortcodes': [':heartpulse:'],
    },
    {
      'codepoint': '1F498',
      'name': 'heart with arrow',
      'category': EmojiCategory.symbols,
      'shortcodes': [':cupid:'],
    },
    {
      'codepoint': '1F49D',
      'name': 'heart with ribbon',
      'category': EmojiCategory.symbols,
      'shortcodes': [':gift_heart:'],
    },
    {
      'codepoint': '1F49E',
      'name': 'revolving hearts',
      'category': EmojiCategory.symbols,
      'shortcodes': [':revolving_hearts:'],
    },
    {
      'codepoint': '1F49F',
      'name': 'heart decoration',
      'category': EmojiCategory.symbols,
      'shortcodes': [':heart_decoration:'],
    },

    // Objects
    {
      'codepoint': '1F525',
      'name': 'fire',
      'category': EmojiCategory.objects,
      'shortcodes': [':fire:'],
      'animated': true,
    },
    {
      'codepoint': '2B50',
      'name': 'star',
      'category': EmojiCategory.objects,
      'shortcodes': [':star:'],
    },
    {
      'codepoint': '1F31F',
      'name': 'glowing star',
      'category': EmojiCategory.objects,
      'shortcodes': [':star2:'],
    },
    {
      'codepoint': '1F4A5',
      'name': 'collision',
      'category': EmojiCategory.objects,
      'shortcodes': [':boom:'],
    },
    {
      'codepoint': '1F4AB',
      'name': 'dizzy',
      'category': EmojiCategory.objects,
      'shortcodes': [':dizzy:'],
    },
    {
      'codepoint': '1F4AF',
      'name': 'hundred points',
      'category': EmojiCategory.objects,
      'shortcodes': [':100:'],
      'animated': true,
    },
    {
      'codepoint': '1F389',
      'name': 'party popper',
      'category': EmojiCategory.objects,
      'shortcodes': [':tada:'],
      'animated': true,
    },
    {
      'codepoint': '1F38A',
      'name': 'confetti ball',
      'category': EmojiCategory.objects,
      'shortcodes': [':confetti_ball:'],
    },
    {
      'codepoint': '1F381',
      'name': 'wrapped gift',
      'category': EmojiCategory.objects,
      'shortcodes': [':gift:'],
    },
    {
      'codepoint': '1F388',
      'name': 'balloon',
      'category': EmojiCategory.objects,
      'shortcodes': [':balloon:'],
    },
    {
      'codepoint': '1F3C6',
      'name': 'trophy',
      'category': EmojiCategory.objects,
      'shortcodes': [':trophy:'],
    },
    {
      'codepoint': '1F3C5',
      'name': 'sports medal',
      'category': EmojiCategory.objects,
      'shortcodes': [':medal:'],
    },
    {
      'codepoint': '1F947',
      'name': 'first place medal',
      'category': EmojiCategory.objects,
      'shortcodes': [':first_place:'],
    },
    {
      'codepoint': '1F4B0',
      'name': 'money bag',
      'category': EmojiCategory.objects,
      'shortcodes': [':moneybag:'],
    },
    {
      'codepoint': '1F4B8',
      'name': 'money with wings',
      'category': EmojiCategory.objects,
      'shortcodes': [':money_with_wings:'],
    },
    {
      'codepoint': '1F4A1',
      'name': 'light bulb',
      'category': EmojiCategory.objects,
      'shortcodes': [':bulb:'],
    },

    // Animals
    {
      'codepoint': '1F436',
      'name': 'dog face',
      'category': EmojiCategory.animals,
      'shortcodes': [':dog:'],
    },
    {
      'codepoint': '1F431',
      'name': 'cat face',
      'category': EmojiCategory.animals,
      'shortcodes': [':cat:'],
    },
    {
      'codepoint': '1F42D',
      'name': 'mouse face',
      'category': EmojiCategory.animals,
      'shortcodes': [':mouse:'],
    },
    {
      'codepoint': '1F439',
      'name': 'hamster',
      'category': EmojiCategory.animals,
      'shortcodes': [':hamster:'],
    },
    {
      'codepoint': '1F430',
      'name': 'rabbit face',
      'category': EmojiCategory.animals,
      'shortcodes': [':rabbit:'],
    },
    {
      'codepoint': '1F98A',
      'name': 'fox',
      'category': EmojiCategory.animals,
      'shortcodes': [':fox:'],
    },
    {
      'codepoint': '1F43B',
      'name': 'bear',
      'category': EmojiCategory.animals,
      'shortcodes': [':bear:'],
    },
    {
      'codepoint': '1F43C',
      'name': 'panda',
      'category': EmojiCategory.animals,
      'shortcodes': [':panda:'],
    },
    {
      'codepoint': '1F428',
      'name': 'koala',
      'category': EmojiCategory.animals,
      'shortcodes': [':koala:'],
    },
    {
      'codepoint': '1F42F',
      'name': 'tiger face',
      'category': EmojiCategory.animals,
      'shortcodes': [':tiger:'],
    },
    {
      'codepoint': '1F981',
      'name': 'lion',
      'category': EmojiCategory.animals,
      'shortcodes': [':lion:'],
    },
    {
      'codepoint': '1F42E',
      'name': 'cow face',
      'category': EmojiCategory.animals,
      'shortcodes': [':cow:'],
    },
    {
      'codepoint': '1F437',
      'name': 'pig face',
      'category': EmojiCategory.animals,
      'shortcodes': [':pig:'],
    },
    {
      'codepoint': '1F438',
      'name': 'frog',
      'category': EmojiCategory.animals,
      'shortcodes': [':frog:'],
    },
    {
      'codepoint': '1F435',
      'name': 'monkey face',
      'category': EmojiCategory.animals,
      'shortcodes': [':monkey_face:'],
    },
    {
      'codepoint': '1F648',
      'name': 'see-no-evil monkey',
      'category': EmojiCategory.animals,
      'shortcodes': [':see_no_evil:'],
    },
    {
      'codepoint': '1F649',
      'name': 'hear-no-evil monkey',
      'category': EmojiCategory.animals,
      'shortcodes': [':hear_no_evil:'],
    },
    {
      'codepoint': '1F64A',
      'name': 'speak-no-evil monkey',
      'category': EmojiCategory.animals,
      'shortcodes': [':speak_no_evil:'],
    },
    {
      'codepoint': '1F412',
      'name': 'monkey',
      'category': EmojiCategory.animals,
      'shortcodes': [':monkey:'],
    },
    {
      'codepoint': '1F414',
      'name': 'chicken',
      'category': EmojiCategory.animals,
      'shortcodes': [':chicken:'],
    },
    {
      'codepoint': '1F427',
      'name': 'penguin',
      'category': EmojiCategory.animals,
      'shortcodes': [':penguin:'],
    },
    {
      'codepoint': '1F426',
      'name': 'bird',
      'category': EmojiCategory.animals,
      'shortcodes': [':bird:'],
    },
    {
      'codepoint': '1F989',
      'name': 'owl',
      'category': EmojiCategory.animals,
      'shortcodes': [':owl:'],
    },
    {
      'codepoint': '1F987',
      'name': 'bat',
      'category': EmojiCategory.animals,
      'shortcodes': [':bat:'],
    },
    {
      'codepoint': '1F43A',
      'name': 'wolf',
      'category': EmojiCategory.animals,
      'shortcodes': [':wolf:'],
    },
    {
      'codepoint': '1F417',
      'name': 'boar',
      'category': EmojiCategory.animals,
      'shortcodes': [':boar:'],
    },
    {
      'codepoint': '1F434',
      'name': 'horse face',
      'category': EmojiCategory.animals,
      'shortcodes': [':horse:'],
    },
    {
      'codepoint': '1F984',
      'name': 'unicorn',
      'category': EmojiCategory.animals,
      'shortcodes': [':unicorn:'],
    },
    {
      'codepoint': '1F41D',
      'name': 'honeybee',
      'category': EmojiCategory.animals,
      'shortcodes': [':bee:'],
    },
    {
      'codepoint': '1F98B',
      'name': 'butterfly',
      'category': EmojiCategory.animals,
      'shortcodes': [':butterfly:'],
    },
    {
      'codepoint': '1F40C',
      'name': 'snail',
      'category': EmojiCategory.animals,
      'shortcodes': [':snail:'],
    },
    {
      'codepoint': '1F41B',
      'name': 'bug',
      'category': EmojiCategory.animals,
      'shortcodes': [':bug:'],
    },

    // Food & Drink
    {
      'codepoint': '1F34E',
      'name': 'red apple',
      'category': EmojiCategory.food,
      'shortcodes': [':apple:'],
    },
    {
      'codepoint': '1F34F',
      'name': 'green apple',
      'category': EmojiCategory.food,
      'shortcodes': [':green_apple:'],
    },
    {
      'codepoint': '1F34A',
      'name': 'tangerine',
      'category': EmojiCategory.food,
      'shortcodes': [':tangerine:'],
    },
    {
      'codepoint': '1F34B',
      'name': 'lemon',
      'category': EmojiCategory.food,
      'shortcodes': [':lemon:'],
    },
    {
      'codepoint': '1F34C',
      'name': 'banana',
      'category': EmojiCategory.food,
      'shortcodes': [':banana:'],
    },
    {
      'codepoint': '1F349',
      'name': 'watermelon',
      'category': EmojiCategory.food,
      'shortcodes': [':watermelon:'],
    },
    {
      'codepoint': '1F347',
      'name': 'grapes',
      'category': EmojiCategory.food,
      'shortcodes': [':grapes:'],
    },
    {
      'codepoint': '1F353',
      'name': 'strawberry',
      'category': EmojiCategory.food,
      'shortcodes': [':strawberry:'],
    },
    {
      'codepoint': '1F352',
      'name': 'cherries',
      'category': EmojiCategory.food,
      'shortcodes': [':cherries:'],
    },
    {
      'codepoint': '1F351',
      'name': 'peach',
      'category': EmojiCategory.food,
      'shortcodes': [':peach:'],
    },
    {
      'codepoint': '1F96D',
      'name': 'mango',
      'category': EmojiCategory.food,
      'shortcodes': [':mango:'],
    },
    {
      'codepoint': '1F34D',
      'name': 'pineapple',
      'category': EmojiCategory.food,
      'shortcodes': [':pineapple:'],
    },
    {
      'codepoint': '1F965',
      'name': 'coconut',
      'category': EmojiCategory.food,
      'shortcodes': [':coconut:'],
    },
    {
      'codepoint': '1F951',
      'name': 'avocado',
      'category': EmojiCategory.food,
      'shortcodes': [':avocado:'],
    },
    {
      'codepoint': '1F346',
      'name': 'eggplant',
      'category': EmojiCategory.food,
      'shortcodes': [':eggplant:'],
    },
    {
      'codepoint': '1F955',
      'name': 'carrot',
      'category': EmojiCategory.food,
      'shortcodes': [':carrot:'],
    },
    {
      'codepoint': '1F33D',
      'name': 'ear of corn',
      'category': EmojiCategory.food,
      'shortcodes': [':corn:'],
    },
    {
      'codepoint': '1F336-FE0F',
      'name': 'hot pepper',
      'category': EmojiCategory.food,
      'shortcodes': [':hot_pepper:'],
    },
    {
      'codepoint': '1F950',
      'name': 'croissant',
      'category': EmojiCategory.food,
      'shortcodes': [':croissant:'],
    },
    {
      'codepoint': '1F35E',
      'name': 'bread',
      'category': EmojiCategory.food,
      'shortcodes': [':bread:'],
    },
    {
      'codepoint': '1F354',
      'name': 'hamburger',
      'category': EmojiCategory.food,
      'shortcodes': [':hamburger:'],
    },
    {
      'codepoint': '1F355',
      'name': 'pizza',
      'category': EmojiCategory.food,
      'shortcodes': [':pizza:'],
    },
    {
      'codepoint': '1F32D',
      'name': 'hot dog',
      'category': EmojiCategory.food,
      'shortcodes': [':hotdog:'],
    },
    {
      'codepoint': '1F35F',
      'name': 'french fries',
      'category': EmojiCategory.food,
      'shortcodes': [':fries:'],
    },
    {
      'codepoint': '1F32E',
      'name': 'taco',
      'category': EmojiCategory.food,
      'shortcodes': [':taco:'],
    },
    {
      'codepoint': '1F32F',
      'name': 'burrito',
      'category': EmojiCategory.food,
      'shortcodes': [':burrito:'],
    },
    {
      'codepoint': '1F363',
      'name': 'sushi',
      'category': EmojiCategory.food,
      'shortcodes': [':sushi:'],
    },
    {
      'codepoint': '1F35C',
      'name': 'steaming bowl',
      'category': EmojiCategory.food,
      'shortcodes': [':ramen:'],
    },
    {
      'codepoint': '1F370',
      'name': 'shortcake',
      'category': EmojiCategory.food,
      'shortcodes': [':cake:'],
    },
    {
      'codepoint': '1F36B',
      'name': 'chocolate bar',
      'category': EmojiCategory.food,
      'shortcodes': [':chocolate_bar:'],
    },
    {
      'codepoint': '1F36D',
      'name': 'lollipop',
      'category': EmojiCategory.food,
      'shortcodes': [':lollipop:'],
    },
    {
      'codepoint': '1F366',
      'name': 'soft ice cream',
      'category': EmojiCategory.food,
      'shortcodes': [':icecream:'],
    },
    {
      'codepoint': '1F377',
      'name': 'wine glass',
      'category': EmojiCategory.food,
      'shortcodes': [':wine_glass:'],
    },
    {
      'codepoint': '1F37A',
      'name': 'beer mug',
      'category': EmojiCategory.food,
      'shortcodes': [':beer:'],
    },
    {
      'codepoint': '2615',
      'name': 'hot beverage',
      'category': EmojiCategory.food,
      'shortcodes': [':coffee:'],
    },

    // Travel & Places
    {
      'codepoint': '2708-FE0F',
      'name': 'airplane',
      'category': EmojiCategory.travel,
      'shortcodes': [':airplane:'],
    },
    {
      'codepoint': '1F697',
      'name': 'automobile',
      'category': EmojiCategory.travel,
      'shortcodes': [':car:'],
    },
    {
      'codepoint': '1F3E0',
      'name': 'house',
      'category': EmojiCategory.travel,
      'shortcodes': [':house:'],
    },
    {
      'codepoint': '1F30D',
      'name': 'globe showing Europe-Africa',
      'category': EmojiCategory.travel,
      'shortcodes': [':earth_africa:'],
    },
    {
      'codepoint': '1F30E',
      'name': 'globe showing Americas',
      'category': EmojiCategory.travel,
      'shortcodes': [':earth_americas:'],
    },
    {
      'codepoint': '1F30F',
      'name': 'globe showing Asia-Australia',
      'category': EmojiCategory.travel,
      'shortcodes': [':earth_asia:'],
    },
    {
      'codepoint': '1F30B',
      'name': 'volcano',
      'category': EmojiCategory.travel,
      'shortcodes': [':volcano:'],
    },
    {
      'codepoint': '1F3D4-FE0F',
      'name': 'snow-capped mountain',
      'category': EmojiCategory.travel,
      'shortcodes': [':mountain_snow:'],
    },
    {
      'codepoint': '1F3DD-FE0F',
      'name': 'desert island',
      'category': EmojiCategory.travel,
      'shortcodes': [':desert_island:'],
    },
    {
      'codepoint': '1F3D6-FE0F',
      'name': 'beach with umbrella',
      'category': EmojiCategory.travel,
      'shortcodes': [':beach:'],
    },
    {
      'codepoint': '2600-FE0F',
      'name': 'sun',
      'category': EmojiCategory.travel,
      'shortcodes': [':sunny:'],
    },
    {
      'codepoint': '1F319',
      'name': 'crescent moon',
      'category': EmojiCategory.travel,
      'shortcodes': [':crescent_moon:'],
    },
    {
      'codepoint': '2B50',
      'name': 'star',
      'category': EmojiCategory.travel,
      'shortcodes': [':star:'],
    },
    {
      'codepoint': '1F308',
      'name': 'rainbow',
      'category': EmojiCategory.travel,
      'shortcodes': [':rainbow:'],
    },
    {
      'codepoint': '26C5',
      'name': 'sun behind cloud',
      'category': EmojiCategory.travel,
      'shortcodes': [':partly_sunny:'],
    },
    {
      'codepoint': '1F327-FE0F',
      'name': 'cloud with rain',
      'category': EmojiCategory.travel,
      'shortcodes': [':cloud_rain:'],
    },
    {
      'codepoint': '26A1',
      'name': 'high voltage',
      'category': EmojiCategory.travel,
      'shortcodes': [':zap:'],
    },
    {
      'codepoint': '2744-FE0F',
      'name': 'snowflake',
      'category': EmojiCategory.travel,
      'shortcodes': [':snowflake:'],
    },

    // Activities
    {
      'codepoint': '26BD',
      'name': 'soccer ball',
      'category': EmojiCategory.activities,
      'shortcodes': [':soccer:'],
    },
    {
      'codepoint': '1F3C0',
      'name': 'basketball',
      'category': EmojiCategory.activities,
      'shortcodes': [':basketball:'],
    },
    {
      'codepoint': '1F3C8',
      'name': 'american football',
      'category': EmojiCategory.activities,
      'shortcodes': [':football:'],
    },
    {
      'codepoint': '26BE',
      'name': 'baseball',
      'category': EmojiCategory.activities,
      'shortcodes': [':baseball:'],
    },
    {
      'codepoint': '1F3BE',
      'name': 'tennis',
      'category': EmojiCategory.activities,
      'shortcodes': [':tennis:'],
    },
    {
      'codepoint': '1F3D0',
      'name': 'volleyball',
      'category': EmojiCategory.activities,
      'shortcodes': [':volleyball:'],
    },
    {
      'codepoint': '1F3B1',
      'name': 'pool 8 ball',
      'category': EmojiCategory.activities,
      'shortcodes': [':8ball:'],
    },
    {
      'codepoint': '1F3B3',
      'name': 'bowling',
      'category': EmojiCategory.activities,
      'shortcodes': [':bowling:'],
    },
    {
      'codepoint': '1F3AE',
      'name': 'video game',
      'category': EmojiCategory.activities,
      'shortcodes': [':video_game:'],
    },
    {
      'codepoint': '1F3B2',
      'name': 'game die',
      'category': EmojiCategory.activities,
      'shortcodes': [':game_die:'],
    },
    {
      'codepoint': '265F-FE0F',
      'name': 'chess pawn',
      'category': EmojiCategory.activities,
      'shortcodes': [':chess_pawn:'],
    },
    {
      'codepoint': '1F3AF',
      'name': 'bullseye',
      'category': EmojiCategory.activities,
      'shortcodes': [':dart:'],
    },
    {
      'codepoint': '1F3BC',
      'name': 'musical score',
      'category': EmojiCategory.activities,
      'shortcodes': [':musical_score:'],
    },
    {
      'codepoint': '1F3B5',
      'name': 'musical note',
      'category': EmojiCategory.activities,
      'shortcodes': [':musical_note:'],
    },
    {
      'codepoint': '1F3B6',
      'name': 'musical notes',
      'category': EmojiCategory.activities,
      'shortcodes': [':notes:'],
    },
    {
      'codepoint': '1F3A4',
      'name': 'microphone',
      'category': EmojiCategory.activities,
      'shortcodes': [':microphone:'],
    },
    {
      'codepoint': '1F3B8',
      'name': 'guitar',
      'category': EmojiCategory.activities,
      'shortcodes': [':guitar:'],
    },
    {
      'codepoint': '1F3B9',
      'name': 'musical keyboard',
      'category': EmojiCategory.activities,
      'shortcodes': [':musical_keyboard:'],
    },
    {
      'codepoint': '1F941',
      'name': 'drum',
      'category': EmojiCategory.activities,
      'shortcodes': [':drum:'],
    },

    // Flags (subset)
    {
      'codepoint': '1F1FA-1F1F8',
      'name': 'flag: United States',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_us:', ':us:'],
    },
    {
      'codepoint': '1F1EC-1F1E7',
      'name': 'flag: United Kingdom',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_gb:', ':gb:'],
    },
    {
      'codepoint': '1F1E9-1F1EA',
      'name': 'flag: Germany',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_de:', ':de:'],
    },
    {
      'codepoint': '1F1EB-1F1F7',
      'name': 'flag: France',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_fr:', ':fr:'],
    },
    {
      'codepoint': '1F1EE-1F1F9',
      'name': 'flag: Italy',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_it:', ':it:'],
    },
    {
      'codepoint': '1F1EA-1F1F8',
      'name': 'flag: Spain',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_es:', ':es:'],
    },
    {
      'codepoint': '1F1F7-1F1FA',
      'name': 'flag: Russia',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_ru:', ':ru:'],
    },
    {
      'codepoint': '1F1E8-1F1F3',
      'name': 'flag: China',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_cn:', ':cn:'],
    },
    {
      'codepoint': '1F1EF-1F1F5',
      'name': 'flag: Japan',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_jp:', ':jp:'],
    },
    {
      'codepoint': '1F1F0-1F1F7',
      'name': 'flag: South Korea',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_kr:', ':kr:'],
    },
    {
      'codepoint': '1F1E7-1F1F7',
      'name': 'flag: Brazil',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_br:', ':br:'],
    },
    {
      'codepoint': '1F1EE-1F1F3',
      'name': 'flag: India',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_in:', ':in:'],
    },
    {
      'codepoint': '1F1E8-1F1E6',
      'name': 'flag: Canada',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_ca:', ':ca:'],
    },
    {
      'codepoint': '1F1E6-1F1FA',
      'name': 'flag: Australia',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_au:', ':au:'],
    },
    {
      'codepoint': '1F1FA-1F1E6',
      'name': 'flag: Ukraine',
      'category': EmojiCategory.flags,
      'shortcodes': [':flag_ua:', ':ua:'],
    },
    {
      'codepoint': '1F3F3-FE0F',
      'name': 'white flag',
      'category': EmojiCategory.flags,
      'shortcodes': [':white_flag:'],
    },
    {
      'codepoint': '1F3F4',
      'name': 'black flag',
      'category': EmojiCategory.flags,
      'shortcodes': [':black_flag:'],
    },
    {
      'codepoint': '1F3C1',
      'name': 'chequered flag',
      'category': EmojiCategory.flags,
      'shortcodes': [':checkered_flag:'],
    },
    {
      'codepoint': '1F6A9',
      'name': 'triangular flag',
      'category': EmojiCategory.flags,
      'shortcodes': [':triangular_flag:'],
    },
    {
      'codepoint': '1F3F3-FE0F-200D-1F308',
      'name': 'rainbow flag',
      'category': EmojiCategory.flags,
      'shortcodes': [':rainbow_flag:'],
    },
  ];
}
