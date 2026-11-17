import 'package:flutter/widgets.dart';

import '../../core/theme/kachava_tokens.dart';

/// Square chat bubble: guest = surface with a line border, staff = wash.
BoxDecoration bubbleDecoration({required bool fromGuest}) => BoxDecoration(
      color: fromGuest ? KachavaTokens.surface : KachavaTokens.wash,
      border: fromGuest ? Border.all(color: KachavaTokens.line) : null,
      borderRadius: BorderRadius.circular(KachavaTokens.radius),
    );
