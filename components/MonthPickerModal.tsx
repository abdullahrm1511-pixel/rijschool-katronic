import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';

import { successFeedback, tapFeedback } from '@/utils/haptics';
import { dutchMonths } from '@/utils/timeSlots';

type MonthPickerModalProps = {
  visible: boolean;
  selectedDate: Date;
  onClose: () => void;
  onSelect: (date: Date) => void;
};

export function MonthPickerModal({
  visible,
  selectedDate,
  onClose,
  onSelect,
}: MonthPickerModalProps) {
  const year = selectedDate.getFullYear();

  return (
    <Modal animationType="slide" transparent visible={visible} onRequestClose={onClose}>
      <Pressable
        style={styles.backdrop}
        onPress={() => {
          tapFeedback();
          onClose();
        }}
      >
        <Pressable style={styles.sheet}>
          <View style={styles.grabber} />
          <View style={styles.header}>
            <Text style={styles.title}>Maand kiezen</Text>
            <Pressable
              onPress={() => {
                tapFeedback();
                onClose();
              }}
              style={({ pressed }) => [styles.closeButton, pressed && styles.pressedInline]}
            >
              <Text style={styles.closeText}>Sluit</Text>
            </Pressable>
          </View>
          <View style={styles.yearRow}>
            <Pressable
              onPress={() => {
                tapFeedback();
                onSelect(new Date(year - 1, selectedDate.getMonth(), 1));
              }}
              style={({ pressed }) => [styles.yearButton, pressed && styles.pressedButton]}
            >
              <Text style={styles.yearButtonText}>Vorig jaar</Text>
            </Pressable>
            <Text style={styles.year}>{year}</Text>
            <Pressable
              onPress={() => {
                tapFeedback();
                onSelect(new Date(year + 1, selectedDate.getMonth(), 1));
              }}
              style={({ pressed }) => [styles.yearButton, pressed && styles.pressedButton]}
            >
              <Text style={styles.yearButtonText}>Volgend jaar</Text>
            </Pressable>
          </View>
          <View style={styles.grid}>
            {dutchMonths.map((month, index) => {
              const active = index === selectedDate.getMonth();
              return (
                <Pressable
                  key={month}
                  onPress={() => {
                    successFeedback();
                    onSelect(new Date(year, index, 1));
                    onClose();
                  }}
                  style={({ pressed }) => [
                    styles.monthButton,
                    active && styles.activeMonth,
                    pressed && styles.pressedButton,
                  ]}
                >
                  <Text style={[styles.monthText, active && styles.activeMonthText]}>{month}</Text>
                </Pressable>
              );
            })}
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    backgroundColor: 'rgba(0,0,0,0.58)',
    flex: 1,
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: '#080b10',
    borderColor: '#1f2937',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    borderWidth: 1,
    padding: 20,
    boxShadow: '0 -18px 36px rgba(0, 0, 0, 0.28)',
  },
  grabber: {
    alignSelf: 'center',
    backgroundColor: '#475569',
    borderRadius: 999,
    height: 5,
    marginBottom: 16,
    width: 42,
  },
  header: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  title: {
    color: '#ffffff',
    fontSize: 22,
    fontWeight: '800',
  },
  closeButton: {
    padding: 8,
  },
  pressedInline: {
    opacity: 0.72,
  },
  closeText: {
    color: '#2563eb',
    fontSize: 16,
    fontWeight: '700',
  },
  yearRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 18,
  },
  yearButton: {
    backgroundColor: '#111827',
    borderRadius: 14,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  pressedButton: {
    opacity: 0.82,
    transform: [{ scale: 0.96 }],
  },
  yearButtonText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '700',
  },
  year: {
    color: '#ffffff',
    fontSize: 20,
    fontWeight: '800',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
    paddingBottom: 16,
  },
  monthButton: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 18,
    borderWidth: 1,
    paddingVertical: 14,
    width: '30.8%',
  },
  activeMonth: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  monthText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
    textTransform: 'capitalize',
  },
  activeMonthText: {
    color: '#ffffff',
  },
});
