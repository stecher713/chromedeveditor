// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark_widgets.dialog;

import 'dart:html';

import 'package:polymer/polymer.dart';

import '../common/spark_widget.dart';
import '../spark_dialog_button/spark_dialog_button.dart';
import '../spark_modal/spark_modal.dart';

@CustomTag('spark-dialog')
class SparkDialog extends SparkWidget {
  // TODO(ussuri): Replace with a regular published property (BUG #2252).
  /**
   * The title of the dialog.
   */
  @published String get title => _title;
  @published set title(String value) {
    _title = value;
    if (_titleElement != null) _titleElement.text = value;
  }

  /**
   * The kind of animation that the overlay should perform on open/close.
   */
  @published String animation = 'scale-slideup';

  bool _activityVisible = false;

  SparkModal _modal;
  String _title = '';
  Element _titleElement;
  FormElement _body;
  Iterable<SparkDialogButton> _buttons;
  List<_ValidatedField> _validatedFields = [];

  SparkDialog.created() : super.created();

  @override
  void enteredView() {
    super.enteredView();

    SparkWidget.enableKeyboardEvents(_modal);

    _modal = $['modal'];
    _titleElement = $['title'];
    _body = $['body'];
    _buttons = SparkWidget.inlineNestedContentNodes($['buttonsContent']);

    title = _title;
    $['progress'].classes.toggle('hidden', !_activityVisible);

    // Listen to the form's global validity changes. Additional listeners are
    // added below to text input fields.
    _body.onChange.listen(_updateFormValidity);
  }

  void show() {
    if (!_modal.opened) {
      _addValidatableFields(
          SparkWidget.inlineNestedContentNodes($['bodyContent']));
      _updateFormValidity();
      _modal.toggle();
    }
  }

  void hide() {
    if (_modal.opened) {
      _modal.toggle();
    }
  }

  bool get activityVisible => _activityVisible;

  void set activityVisible(bool visible) {
    _activityVisible = visible;
    $['progress'].classes.toggle('hidden', !_activityVisible);
  }

  void _addValidatableFields(Iterable<Node> candidates) {
    _validatedFields.clear();
    _addValidatableFieldsImpl(candidates);
  }

  void _addValidatableFieldsImpl(Iterable<Node> candidates) {
    candidates.forEach((Element element) {
      if (element is InputElement) {
        if (element.willValidate) {
          _validatedFields.add(
              new _ValidatedField(element, _updateFormValidity));
        }
      } else {
        _addValidatableFieldsImpl(element.children);
      }
    });
  }

  void _updateFormValidity([_]) {
    // NOTE: _body.checkValidity() didn't work.
    final bool formIsValid = _validatedFields.every((f) => f.isValid);
    _buttons.forEach((b) => b.updateParentFormValidity(formIsValid));
  }
}

@reflectable
class _ValidatedField {
  static const INVALID_CLASS = 'invalid';
  
  final InputElement _element;
  final Function _onValidityChange;
  bool _wasVisited = false;
  bool _isValid;

  bool get isValid => _isValid;

  _ValidatedField(this._element, this._onValidityChange) {
    // Just listening to the [_body.onChange] is not enough to update
    // the validity in real-time as the user types.
    _element
        ..onFocus.listen(_setVisited)
        ..onClick.listen(_setVisited)
        ..onInput.listen(_updateValidity)
        ..onPaste.listen(_updateValidity)
        ..onReset.listen(_updateValidity);
    _element.classes.remove('invalid');
  }

  void _setVisited([_]) {
    _wasVisited = true;
    _updateValidity();
  }
  
  void _updateValidity([_]) {
    _isValid = _element.disabled || _element.checkValidity();
    // Don't rely on the automatic ':invalid' pseudo-class for finer control.
    _element.classes.toggle('invalid', _wasVisited && !_isValid);
    _onValidityChange();
  }
}
