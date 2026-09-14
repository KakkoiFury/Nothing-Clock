library font_awesome_flutter;

import 'package:flutter/widgets.dart';

/// Compatibility file for modern Flutter.
///
/// font_awesome_flutter 10.7.0 originally implemented
/// IconDataBrands, IconDataSolid, IconDataRegular,
/// IconDataLight and IconDataThin by extending IconData.
///
/// Modern Flutter declares IconData as final.
///
/// The generated FontAwesomeIcons file has been patched to
/// construct ordinary IconData objects directly.
