import { InstructionPart, ProgressStatus } from '@/types';

export const instructionParts: InstructionPart[] = [
  { id: 1, title: 'Zit- en stuurhouding, autogordel, spiegels' },
  { id: 2, title: 'Schakelen' },
  { id: 3, title: 'Stuurbehandeling' },
  { id: 4, title: 'Remmen' },
  { id: 5, title: 'Wegrijden, verlaten van uitrit en rijden in inrit' },
  { id: 6, title: 'Rijden op rechte weggedeelten' },
  { id: 7, title: 'Rijden en volgen van bochten' },
  { id: 8, title: 'Afslaan' },
  { id: 9, title: 'Gedrag nabij en op kruispunten' },
  { id: 10, title: 'Invoegen en uitvoegen' },
  { id: 11, title: 'Inhalen en voorbijgaan' },
  { id: 12, title: 'Tegemoetkomen en ingehaald worden' },
  { id: 13, title: 'Wisselen van rijstrook' },
  { id: 14, title: 'Zijdelingse verplaatsingen' },
  { id: 15, title: 'Gedrag op rotondes' },
  { id: 16, title: 'Gedrag nabij en op bijzondere weggedeelten' },
  { id: 17, title: 'Hellingproef' },
  { id: 18, title: 'Achteruitrijden' },
  { id: 19, title: 'Parkeren' },
  { id: 20, title: 'Keren' },
  { id: 21, title: 'Stopproef' },
].sort((a, b) => a.title.localeCompare(b.title, 'nl'));

export const progressStatuses: ProgressStatus[] = ['Slecht', 'Matig', 'Goed', 'Beheerst'];

export const defaultLessonAmount = 55;
