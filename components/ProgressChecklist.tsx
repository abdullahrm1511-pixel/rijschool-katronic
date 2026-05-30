import { useState } from 'react';
import { LayoutAnimation, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { instructionParts, progressStatuses } from '@/data/mockData';
import { useAppState } from '@/data/AppState';
import { ProgressStatus } from '@/types';
import { actionFeedback, successFeedback, tapFeedback } from '@/utils/haptics';

type ProgressChecklistProps = {
  studentId: string;
  lessonId?: string;
  filter?: ProgressStatus | 'Alles';
};

const statusColors: Record<ProgressStatus, string> = {
  Slecht: '#dc2626',
  Matig: '#f59e0b',
  Goed: '#16a34a',
  Beheerst: '#2563eb',
};

export function ProgressChecklist({ studentId, lessonId, filter = 'Alles' }: ProgressChecklistProps) {
  const { getStudentProgress, lessonTreatments, toggleLessonTreatment, updateProgressStatus } =
    useAppState();
  const [openPartId, setOpenPartId] = useState<number | null>(null);
  const [draftNotes, setDraftNotes] = useState<Record<number, string>>({});

  const visibleParts = instructionParts.filter((part) => {
    if (filter === 'Alles') {
      return true;
    }
    return getStudentProgress(studentId, part.id).status === filter;
  });

  return (
    <View style={styles.container}>
      {visibleParts.map((part) => {
        const progress = getStudentProgress(studentId, part.id);
        const checked = lessonTreatments.some(
          (item) => item.lessonId === lessonId && item.partId === part.id,
        );
        const expanded = openPartId === part.id;
        const noteValue = draftNotes[part.id] ?? progress.note;

        return (
          <View key={part.id} style={styles.item}>
            <Pressable
              onPress={() => {
                tapFeedback();
                LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
                setOpenPartId(expanded ? null : part.id);
              }}
              style={({ pressed }) => [styles.itemHeader, pressed && styles.pressedHeader]}
            >
              {lessonId ? (
                <Pressable
                  onPress={() => {
                    actionFeedback();
                    toggleLessonTreatment(lessonId, studentId, part.id);
                  }}
                  style={({ pressed }) => [
                    styles.checkbox,
                    checked && styles.checkboxChecked,
                    pressed && styles.pressedCheckbox,
                  ]}
                  hitSlop={10}
                >
                  <Text style={styles.checkboxText}>{checked ? '✓' : ''}</Text>
                </Pressable>
              ) : null}
              <View style={styles.itemMain}>
                <Text style={styles.partTitle}>{part.title}</Text>
                <Text style={styles.count}>{progress.treatedCount}x behandeld</Text>
                {progress.note ? <Text style={styles.lastNote}>{progress.note}</Text> : null}
              </View>
              <View style={[styles.statusBadge, { backgroundColor: statusColors[progress.status] }]}>
                <Text style={styles.statusText}>{progress.status}</Text>
              </View>
            </Pressable>
            {expanded ? (
              <View style={styles.accordion}>
                <View style={styles.statusRow}>
                  {progressStatuses.map((status) => (
                    <Pressable
                      key={status}
                      onPress={() => {
                        tapFeedback();
                        updateProgressStatus(studentId, part.id, { status });
                      }}
                      style={({ pressed }) => [
                        styles.statusButton,
                        progress.status === status && { backgroundColor: statusColors[status] },
                        pressed && styles.pressedStatus,
                      ]}
                    >
                      <Text
                        style={[
                          styles.statusButtonText,
                          progress.status === status && styles.activeStatusButtonText,
                        ]}
                      >
                        {status}
                      </Text>
                    </Pressable>
                  ))}
                </View>
                <TextInput
                  multiline
                  placeholder="Notitie bij dit onderdeel"
                  placeholderTextColor="#64748b"
                  value={noteValue}
                  onChangeText={(text) => setDraftNotes((current) => ({ ...current, [part.id]: text }))}
                  style={styles.noteInput}
                />
                <Pressable
                  onPress={() => {
                    successFeedback();
                    updateProgressStatus(studentId, part.id, { note: noteValue });
                  }}
                  style={({ pressed }) => [styles.saveButton, pressed && styles.pressedSave]}
                >
                  <Text style={styles.saveText}>Notitie opslaan</Text>
                </Pressable>
              </View>
            ) : null}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 10,
  },
  item: {
    backgroundColor: '#111827',
    borderColor: '#1f2937',
    borderRadius: 20,
    borderWidth: 1,
    overflow: 'hidden',
    boxShadow: '0 8px 18px rgba(0, 0, 0, 0.14)',
  },
  itemHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: 12,
    minHeight: 82,
    padding: 14,
  },
  pressedHeader: {
    opacity: 0.78,
  },
  checkbox: {
    alignItems: 'center',
    borderColor: '#64748b',
    borderRadius: 8,
    borderWidth: 2,
    height: 28,
    justifyContent: 'center',
    width: 28,
  },
  checkboxChecked: {
    backgroundColor: '#2563eb',
    borderColor: '#2563eb',
  },
  pressedCheckbox: {
    transform: [{ scale: 0.9 }],
  },
  checkboxText: {
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '900',
  },
  itemMain: {
    flex: 1,
  },
  partTitle: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '800',
    lineHeight: 20,
  },
  count: {
    color: '#94a3b8',
    fontSize: 13,
    marginTop: 5,
  },
  lastNote: {
    color: '#cbd5e1',
    fontSize: 13,
    marginTop: 6,
  },
  statusBadge: {
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 6,
  },
  statusText: {
    color: '#ffffff',
    fontSize: 11,
    fontWeight: '900',
  },
  accordion: {
    borderTopColor: '#1f2937',
    borderTopWidth: 1,
    padding: 14,
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  statusButton: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  pressedStatus: {
    opacity: 0.78,
    transform: [{ scale: 0.96 }],
  },
  statusButtonText: {
    color: '#cbd5e1',
    fontSize: 13,
    fontWeight: '800',
  },
  activeStatusButtonText: {
    color: '#ffffff',
  },
  noteInput: {
    backgroundColor: '#0f172a',
    borderColor: '#1f2937',
    borderRadius: 16,
    borderWidth: 1,
    color: '#ffffff',
    fontSize: 15,
    marginTop: 12,
    minHeight: 92,
    padding: 12,
    textAlignVertical: 'top',
  },
  saveButton: {
    alignItems: 'center',
    backgroundColor: '#2563eb',
    borderRadius: 16,
    marginTop: 10,
    paddingVertical: 13,
  },
  pressedSave: {
    opacity: 0.82,
    transform: [{ scale: 0.985 }],
  },
  saveText: {
    color: '#ffffff',
    fontSize: 15,
    fontWeight: '900',
  },
});
