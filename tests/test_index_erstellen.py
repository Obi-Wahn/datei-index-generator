import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parent.parent / "00_index_erstellen.py"
_spec = importlib.util.spec_from_file_location("index_erstellen", MODULE_PATH)
index_erstellen = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(index_erstellen)


class NaturalSortKeyTests(unittest.TestCase):
    def test_numbers_sort_numerically_not_lexically(self):
        names = ["datei10.pdf", "datei2.pdf", "datei1.pdf"]
        self.assertEqual(
            sorted(names, key=index_erstellen.natural_sort_key),
            ["datei1.pdf", "datei2.pdf", "datei10.pdf"],
        )

    def test_case_insensitive(self):
        names = ["Banane.pdf", "apfel.pdf"]
        self.assertEqual(
            sorted(names, key=index_erstellen.natural_sort_key),
            ["apfel.pdf", "Banane.pdf"],
        )

    def test_superscript_digits_do_not_crash(self):
        names = ["Formel 1²2.pdf", "²1.pdf", "Formel 1.pdf"]
        self.assertEqual(
            sorted(names, key=index_erstellen.natural_sort_key),
            ["Formel 1.pdf", "Formel 1²2.pdf", "²1.pdf"],
        )

    def test_names_without_numbers(self):
        names = ["c.pdf", "a.pdf", "b.pdf"]
        self.assertEqual(
            sorted(names, key=index_erstellen.natural_sort_key),
            ["a.pdf", "b.pdf", "c.pdf"],
        )


class GetGroupLetterTests(unittest.TestCase):
    def test_regular_letter_is_uppercased(self):
        self.assertEqual(index_erstellen.get_group_letter("apfel.pdf"), "A")

    def test_umlaut_mapping(self):
        self.assertEqual(index_erstellen.get_group_letter("Ärger.html"), "A")
        self.assertEqual(index_erstellen.get_group_letter("Ötzi.html"), "O")
        self.assertEqual(index_erstellen.get_group_letter("Übung.html"), "U")
        self.assertEqual(index_erstellen.get_group_letter("ßtest.html"), "S")

    def test_non_letter_first_character_falls_back_to_hash(self):
        self.assertEqual(index_erstellen.get_group_letter("1_intro.pdf"), "#")
        self.assertEqual(index_erstellen.get_group_letter("_privat.pdf"), "#")


class LoadTemplateTests(unittest.TestCase):
    def setUp(self):
        self._original_template_file = index_erstellen.TEMPLATE_FILE

    def tearDown(self):
        index_erstellen.TEMPLATE_FILE = self._original_template_file

    def test_missing_template_file_raises_clear_error(self):
        index_erstellen.TEMPLATE_FILE = self._original_template_file.parent / "does_not_exist.html"
        with self.assertRaises(FileNotFoundError):
            index_erstellen.load_template()

    def test_missing_marker_raises_clear_error(self):
        with tempfile.TemporaryDirectory() as tmp_dir:
            broken_template = Path(tmp_dir) / "broken_template.html"
            broken_template.write_text("<html></html>", encoding="utf-8")
            index_erstellen.TEMPLATE_FILE = broken_template
            with self.assertRaises(ValueError):
                index_erstellen.load_template()

    def test_valid_template_splits_at_marker(self):
        html_top, html_bottom = index_erstellen.load_template()
        self.assertNotIn(index_erstellen.CONTENT_MARKER, html_top)
        self.assertNotIn(index_erstellen.CONTENT_MARKER, html_bottom)


if __name__ == "__main__":
    unittest.main()
