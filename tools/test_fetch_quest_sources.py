"""Regression fixtures for dialogue that starts directly under a Progress heading.

Derived from current Forever quest pages 91736 and 91738, fetched 2026-11-11.
"""
import unittest
from fetch_quest_sources import parse_wowhead


class QuestSourceTests(unittest.TestCase):
    def test_repeatable_device_progress_is_not_lost(self):
        result = parse_wowhead('<h1 class="heading-size-1">Applejack Still</h1>'
            '<h2 classes="first" class="heading-size-3">Progress</h2>'
            'A strong scent of apples burns your nose as you inspect the device.'
            '<table class="icon-list"><tr><td>Shiny Red Apple (4)</td></tr></table>'
            '<h2>Rewards</h2>Experience')
        self.assertEqual(result['progress'], 'A strong scent of apples burns your nose as you inspect the device.')
        self.assertIsNone(result['objective'])
        self.assertIsNone(result['detail'])

    def test_linked_repeatable_turnin_preserves_text_without_item_table(self):
        result = parse_wowhead('<h1 class="heading-size-1">An Apple Treat</h1>'
            '<h2 classes="first" class="heading-size-3">Progress</h2>'
            "The sergeant's eyes light up as he notices your bottle of "
            '<a href="/forever/item=247824">Thunder Applejack</a>...'
            '<table><tr><td>1 Thunder Applejack</td></tr></table>')
        self.assertEqual(result['progress'], "The sergeant's eyes light up as he notices your bottle of Thunder Applejack...")
        self.assertNotIn('1 Thunder', result['progress'])

    def test_regular_hidden_reply_and_player_marker(self):
        result = parse_wowhead('<h1 class="heading-size-1">Known quest</h1>Bring the item.<table></table>'
            '<h2>Description</h2>Speak to &lt;name&gt;.<h2>Progress</h2>'
            '<div id="lknlksndgg-progress" style="display: none">Hello, &lt;name&gt;.<br />Ready?</div>'
            '<h2>Completion</h2><div id="lknlksndgg-completion">Well done.</div><h2>Rewards</h2>Gold')
        self.assertEqual(result['objective'], 'Bring the item.')
        self.assertEqual(result['detail'], 'Speak to <name>.')
        self.assertEqual(result['progress'], 'Hello, <name>.\nReady?')
        self.assertEqual(result['complete'], 'Well done.')


    def test_provided_item_widget_is_not_objective_dialogue(self):
        result = parse_wowhead('<h1 class="heading-size-1">Call of Earth</h1>'
            'Find Spirit Rock and drink the <a href="/forever/item=6635">Earth Sapta</a>.'
            '<div class="pad"></div>\n\nProvided item: \n'
            '<table class="icon-list"><tr><td>Earth Sapta (1)</td></tr></table>'
            '<h2>Description</h2>Listen to the spirit.<h2>Rewards</h2>Experience')
        self.assertEqual(result['objective'], 'Find Spirit Rock and drink the Earth Sapta.')
        self.assertNotIn('Provided item', result['objective'])
        self.assertEqual(result['detail'], 'Listen to the spirit.')


if __name__ == '__main__':
    unittest.main()
