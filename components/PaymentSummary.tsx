import { StyleSheet, Text, View } from 'react-native';

type PaymentSummaryProps = {
  amount: number;
  label?: string;
};

export function PaymentSummary({ amount, label = 'Openstaand bedrag' }: PaymentSummaryProps) {
  return (
    <View style={styles.card}>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.amount}>EUR {amount.toFixed(2)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 22,
    borderWidth: 1,
    padding: 18,
    boxShadow: '0 12px 24px rgba(0, 0, 0, 0.16)',
  },
  label: {
    color: '#94a3b8',
    fontSize: 14,
    marginBottom: 6,
  },
  amount: {
    color: '#ffffff',
    fontSize: 30,
    fontWeight: '800',
  },
});
