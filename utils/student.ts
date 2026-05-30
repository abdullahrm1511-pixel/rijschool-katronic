export const calculateAge = (birthDate: string) => {
  const normalized = birthDate.trim();
  if (!normalized) {
    return '';
  }

  const dutchMatch = normalized.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$/);
  const date = dutchMatch
    ? new Date(Number(dutchMatch[3]), Number(dutchMatch[2]) - 1, Number(dutchMatch[1]))
    : new Date(normalized);
  if (Number.isNaN(date.getTime())) {
    return '';
  }

  const today = new Date();
  let age = today.getFullYear() - date.getFullYear();
  const birthdayThisYear = new Date(today.getFullYear(), date.getMonth(), date.getDate());
  if (today < birthdayThisYear) {
    age -= 1;
  }

  return age >= 0 ? String(age) : '';
};
