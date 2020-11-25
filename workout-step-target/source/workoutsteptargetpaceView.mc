using Toybox.WatchUi;
using Toybox.Graphics;

class workoutsteptargetpaceView extends WatchUi.DataField {
  hidden var mValue;
  hidden var mValueType;
  hidden var mTargetType;
  hidden var mMetric;
  hidden var mUseSpeed;
  hidden var mMaxHR;
  hidden var mCurrentWorkoutStep;
  hidden var mCurrentLayout;

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
    mValue = "---";
    // Types: 1 = float, 2 = int, 3 = string
    mValueType = 3;
    mTargetType = "NO";
    mMetric = System.getDeviceSettings().paceUnits == System.UNIT_METRIC
                  ? true
                  : false;
    mUseSpeed = Application.getApp().getProperty("useSpeed");
    mMaxHR =
        UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC)[5];
    mCurrentWorkoutStep = null;
    mCurrentLayout = SINGLE;
  }

  function stepNotEquals(stepa, stepb) {
    return stepa.durationType != stepb.durationType ||
           stepa.durationValue != stepb.durationValue ||
           stepa.targetType != stepb.targetType ||
           stepa.targetValueHigh != stepb.targetValueHigh ||
           stepa.targetValueLow != stepb.targetValueLow;
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

    if (mValue.length() > 10) {
      valueView.setFont(4 - heightRatio < 0 ? 0 : 4 - heightRatio);
    } else {
      valueView.setFont(5 - heightRatio);
    }

    View.findDrawableById("label").setText(Rez.Strings.label);
    return true;
  }

  function convertPace(speed) {
    var factor = mMetric ? 1000.0 : 1609.0;
    var secondsPerUnit = factor / speed;
    secondsPerUnit = (secondsPerUnit + 0.5).toNumber();
    var minutes = (secondsPerUnit / 60);
    var seconds = (secondsPerUnit % 60);
    return Lang.format("$1$:$2$", [ minutes, seconds.format("%02u") ]);
  }

  function setStepValue(step,intensity,sport) {
    if (step.targetType == 0) {
      if (mUseSpeed) {
        mTargetType = "SPEED";
        var factor = mMetric ? 3.6 : 2.23694;
        var minSpeed = step.targetValueLow * factor;
        var maxSpeed = step.targetValueHigh * factor;
        mValue = minSpeed.format("%.2f") + "-" + maxSpeed.format("%.2f");
      } else {
        mTargetType = "PACE";
        var minPace = convertPace(step.targetValueLow);
        var maxPace = convertPace(step.targetValueHigh);
        mValue = maxPace + "-" + minPace;
      }
    }
    if (step.targetType == 1) {
      mTargetType = "HR";
      var minHR = 0;
      var maxHR = 0;

      if (step.targetValueLow < 100) {
        minHR = ((step.targetValueLow / 100.0) *
                 UserProfile.getHeartRateZones(
                     UserProfile.HR_ZONE_SPORT_GENERIC)[5])
                    .format("%d");
      } else {
        minHR = step.targetValueLow - 100;
      }

      if (step.targetValueHigh == 0) {
        minHR =
            (UserProfile.getHeartRateZones(
                 UserProfile.HR_ZONE_SPORT_GENERIC)[step.targetValueLow - 1])
                .format("%d");
        maxHR = (UserProfile.getHeartRateZones(
                     UserProfile.HR_ZONE_SPORT_GENERIC)[step.targetValueLow])
                    .format("%d");
      } else if (step.targetValueHigh < 100) {
        maxHR = ((step.targetValueHigh / 100.0) *
                 UserProfile.getHeartRateZones(
                     UserProfile.HR_ZONE_SPORT_GENERIC)[5])
                    .format("%d");
      } else {
        maxHR = step.targetValueHigh - 100;
      }
      mValue = minHR + "-" + maxHR;
    }
    if (step.targetType == 2) {
      mTargetType = "INTENS.";
      if(intensity == 0){
        if(sport == 1){
      	mValue = "RUN";
      	} else if (sport == 2){
      	mValue = "BIKE";
      	} else {
      	mValue = "ACTIVE";
      	}
      }
      else if(intensity == 1){
      	mValue = "REST";
      }
      else if(intensity == 2){
      	mValue = "WARMUP";
      }
      else if(intensity == 3){
      	mValue = "COOLDOWN";
      }
      else if(intensity == 4){
      	mValue = "RECOVER";
      }
      else if(intensity == 5){
      	mValue = "INTERVAL";
      }
      else if(intensity == 6){
      	mValue = "OTHER";
      }
      else {
        mValue = "---";
      }
    }
    if (step.targetType == 3) {
      mTargetType = "CADENCE";
      mValue = step.targetValueLow + "-" + step.targetValueHigh;
    }
    if (step.targetType > 3) {
      mTargetType = "NOT";
      mValue = "SUPPORTED";
    }
    mValueType = 3;
  }

  // The given info object contains all the current workout information.
  // Calculate a value and save it locally in this method.
  // Note that compute() and onUpdate() are asynchronous, and there is no
  // guarantee that compute() will be called before onUpdate().
  function compute(info) {
    // See Activity.Info in the documentation for available information.
    if (Activity has : getCurrentWorkoutStep) {
      var workoutStepInfo = Activity.getCurrentWorkoutStep();
      if (workoutStepInfo != null) {
        if (workoutStepInfo has : step) {
          if (workoutStepInfo.step instanceof Activity.WorkoutStep) {
            if (mCurrentWorkoutStep == null ||
                stepNotEquals(mCurrentWorkoutStep, workoutStepInfo.step)) {
              setStepValue(workoutStepInfo.step, workoutStepInfo.intensity, workoutStepInfo.sport);
              mCurrentWorkoutStep = workoutStepInfo.step;
            }
          } else {
            System.println("in workoutintervalstep");
          }
        }
      } else {
        mValue = "---";
        mValueType = 3;
        mTargetType = "NO";
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

    label.setText(mTargetType + " TGT");

    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
  }
}
