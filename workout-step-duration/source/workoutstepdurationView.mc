using Toybox.WatchUi;
using Toybox.Graphics;

class workoutstepdurationView extends WatchUi.DataField {
  hidden var mValue;
  hidden var mValueType;
  hidden var mDurationType;
  hidden var mMetric;
  hidden var mCurrentLayout;
  hidden var mStepStartDistance;
  hidden var mStepStartTime;
  hidden var mStepDurationType;
  hidden var mStepDurationValue;

  enum {
    SINGLE,
    TOP,
    BOTTOM,
    MIDDLE,
    LBQ,
    RBQ,
    RTQ,
    LTQ,
    ML,
    MR
  }

  function
  initialize() {
    DataField.initialize();
    mValue = "Supported";
    // Types: 1 = float, 2 = int, 3 = string
    mValueType = 3;
    mDurationType = "Not";
    mMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC
                  ? true
                  : false;
    mCurrentLayout = SINGLE;
    mStepStartTime = 0;
    mStepStartDistance = 0;
    mStepDurationType = 999;
    mStepDurationValue = 0;
  }

  function getLayoutPosition() {
    var obscurityFlags = DataField.getObscurityFlags();
    if (obscurityFlags == OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_BOTTOM |
        OBSCURE_RIGHT) {
      mCurrentLayout = SINGLE;
    }
    if (obscurityFlags == OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_RIGHT) {
      mCurrentLayout = TOP;
    }
    if (obscurityFlags == OBSCURE_BOTTOM | OBSCURE_LEFT | OBSCURE_RIGHT) {
      mCurrentLayout = BOTTOM;
    }
    if (obscurityFlags == OBSCURE_LEFT | OBSCURE_RIGHT) {
      mCurrentLayout = MIDDLE;
    }
    if (obscurityFlags == OBSCURE_BOTTOM | OBSCURE_LEFT) {
      mCurrentLayout = LBQ;
    }
    if (obscurityFlags == OBSCURE_BOTTOM | OBSCURE_RIGHT) {
      mCurrentLayout = RBQ;
    }
    if (obscurityFlags == OBSCURE_TOP | OBSCURE_LEFT) {
      mCurrentLayout = LTQ;
    }
    if (obscurityFlags == OBSCURE_TOP | OBSCURE_RIGHT) {
      mCurrentLayout = RTQ;
    }
    if (obscurityFlags == OBSCURE_LEFT) {
      mCurrentLayout = ML;
    }
    if (obscurityFlags == OBSCURE_RIGHT) {
      mCurrentLayout = MR;
    }
  }

  // Set your layout here. Anytime the size of obscurity of
  // the draw context is changed this will be called.
  function onLayout(dc) {
    getLayoutPosition();
    var align = 0;

    if (mCurrentLayout == ML || mCurrentLayout == LTQ ||
        mCurrentLayout == LBQ) {
      View.setLayout(Rez.Layouts.AlignRightLayout(dc));
      align = 1;
    } else if (mCurrentLayout == MR || mCurrentLayout == RTQ ||
               mCurrentLayout == RBQ) {
      View.setLayout(Rez.Layouts.AlignLeftLayout(dc));
      align = 2;
    } else {
      View.setLayout(Rez.Layouts.MainLayout(dc));
    }

    var heightRatio = System.getDeviceSettings().screenHeight / dc.getHeight();
    var labelView = View.findDrawableById("label");
    var valueView = View.findDrawableById("value");

    if (align == 1) {
      labelView.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
      valueView.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
      labelView.locX = dc.getWidth() - 5;
      valueView.locX = dc.getWidth() - 5;
    } else if (align == 2) {
      labelView.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
      valueView.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
    }

    if (mCurrentLayout == RBQ || mCurrentLayout == LBQ ||
        mCurrentLayout == BOTTOM) {
      labelView.locY =
          labelView.locY - Graphics.getFontHeight(Graphics.FONT_XTINY);
      valueView.locY =
          valueView.locY + (Graphics.getFontHeight(Graphics.FONT_XTINY) / 2);
    } else if (mCurrentLayout == MIDDLE || mCurrentLayout == MR ||
               mCurrentLayout == ML) {
      labelView.locY =
          labelView.locY - (Graphics.getFontHeight(Graphics.FONT_XTINY) * 0.75);
      valueView.locY =
          valueView.locY + (Graphics.getFontHeight(Graphics.FONT_XTINY) * 0.75);
    } else {
      labelView.locY =
          labelView.locY - (Graphics.getFontHeight(Graphics.FONT_XTINY) / 2);
      valueView.locY =
          valueView.locY + Graphics.getFontHeight(Graphics.FONT_XTINY);
    }

    if (mValue.length() > 9) {
      valueView.setFont(4 - heightRatio < 0 ? 0 : 4 - heightRatio);
    } else if (mValue.length() > 7) {
      valueView.setFont(5 - heightRatio);
    } else {
      valueView.setFont(6 - heightRatio);
    }

    View.findDrawableById("label").setText(Rez.Strings.label);
    return true;
  }

  function setStepDuration(step) {
    mStepStartTime = Activity.getActivityInfo().elapsedTime;
    mStepStartDistance = Activity.getActivityInfo().elapsedDistance;
    mStepDurationType = step.durationType;
    mStepDurationValue = step.durationValue.toNumber();
  }

  // The given info object contains all the current workout information.
  // Calculate a value and save it locally in this method.
  // Note that compute() and onUpdate() are asynchronous, and there is no
  // guarantee that compute() will be called before onUpdate().
  function compute(info) {
    // See Activity.Info in the documentation for available information.
    if (mStepDurationType == 0) {  // TIME
      mDurationType = "Time";
      var remaining =
          ((mStepDurationValue * 1000) -
           (Activity.getActivityInfo().elapsedTime - mStepStartTime)) /
          1000;
      var minutes = (remaining / 60);
      var seconds = (remaining % 60);
      mValue = Lang.format("$1$:$2$", [ minutes, seconds.format("%02u") ]);
    } else if (mStepDurationType == 1) {  // Distance
      mDurationType = "Distance";

      var remaining = mStepDurationValue -
                      ((Activity.getActivityInfo().elapsedDistance).toNumber() -
                       mStepStartDistance);

      var factor = 1000;
      var smallunitfactor = 1000;
      var unit = "km";
      var smallunit = "m";

      if (!mMetric) {
        factor = 1609;
        smallunitfactor = 1760;
        unit = "mi";
        smallunit = "yd";
      }

      if ((remaining / factor) > 1) {
        mValue =
            ((remaining * 1.0) / (factor * 1.0)).format("%.3f") + "" + unit;
      } else {
        mValue =
            (remaining / factor * smallunitfactor).toNumber() + "" + smallunit;
      }

    } else {  // NOT SUPPORTED YET
      mValue = "Supported";
      // Types: 1 = float, 2 = int, 3 = string
      mValueType = 3;
      mDurationType = "Not";
    }
  }

  function onWorkoutStarted() {
    if (Activity has : getCurrentWorkoutStep) {
      var workoutStepInfo = Activity.getCurrentWorkoutStep();
      if (workoutStepInfo != null) {
        if (workoutStepInfo has : step) {
          if (workoutStepInfo.step instanceof Activity.WorkoutStep) {
            setStepDuration(workoutStepInfo.step);
          }
        }
      }
    }
  }

  function onWorkoutStepComplete() {
    if (Activity has : getCurrentWorkoutStep) {
      var workoutStepInfo = Activity.getCurrentWorkoutStep();
      if (workoutStepInfo != null) {
        if (workoutStepInfo has : step) {
          if (workoutStepInfo.step instanceof Activity.WorkoutStep) {
            setStepDuration(workoutStepInfo.step);
          }
        }
      }
    }
  }

  // Display the value you computed here. This will be called
  // once a second when the data field is visible.
  function onUpdate(dc) {
    // Set the background color
    View.findDrawableById("Background").setColor(getBackgroundColor());

    // Set the foreground color and value
    var label = View.findDrawableById("label");
    var value = View.findDrawableById("value");
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
      value.setColor(Graphics.COLOR_WHITE);
      label.setColor(Graphics.COLOR_WHITE);
    } else {
      value.setColor(Graphics.COLOR_BLACK);
      label.setColor(Graphics.COLOR_BLACK);
    }

    if (mValueType == 1) {
      value.setText(mValue.format("%.2f"));
    }
    if (mValueType == 2) {
      value.setText(mValue.format("%d"));
    }
    if (mValueType == 3) {
      value.setText(mValue);
    }

    label.setText(mDurationType);

    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
  }
}
