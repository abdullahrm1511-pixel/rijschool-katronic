import * as Haptics from 'expo-haptics';

const canUseHaptics = process.env.EXPO_OS === 'ios';

export const tapFeedback = () => {
  if (canUseHaptics) {
    Haptics.selectionAsync();
  }
};

export const actionFeedback = () => {
  if (canUseHaptics) {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }
};

export const successFeedback = () => {
  if (canUseHaptics) {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  }
};

export const warningFeedback = () => {
  if (canUseHaptics) {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
  }
};
