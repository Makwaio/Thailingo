import 'package:flutter/material.dart';
import '../ui/theme/app_theme.dart';

class GuideBookScreen extends StatefulWidget {
  final int initialTab;
  const GuideBookScreen({super.key, this.initialTab = 0});

  @override
  State<GuideBookScreen> createState() => _GuideBookScreenState();
}

class _GuideBookScreenState extends State<GuideBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = [
    ('The Basics', '🇹🇭'),
    ('Tones Guide', '🎵'),
    ('Phonetics', '🔤'),
    ('Alphabet', '🔡'),
    ('Survival', '🆘'),
    ('Culture', '🙏'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.thaiNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '📖 Thai Companion Guide',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppTheme.thaiGold,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.thaiGold,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: _tabs
              .map((t) => Tab(text: '${t.$2} ${t.$1}'))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _BasicsTab(),
          _TonesTab(),
          _PhoneticsTab(),
          _AlphabetTab(),
          _SurvivalTab(),
          _CultureTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.thaiNavy)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.blueTint,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.thaiNavy.withValues(alpha: 0.2)),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  const _TipBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.thaiGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.thaiGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  final String text;
  const _CodeBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF58A6FF),
              fontFamily: 'monospace',
              height: 1.6)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 1 — The Basics
// ─────────────────────────────────────────────────────────────────────

class _BasicsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: const [
        _Section(
          title: 'Welcome to Thai! 🇹🇭',
          children: [
            _InfoBox(
                'This app teaches Bangkok spoken Thai — the everyday language used in the capital. It\'s casual, practical, and what you\'ll actually hear on the streets of Bangkok.\n\nFormal Thai exists (used in news, official settings) but Bangkokians speak a friendly, relaxed version. That\'s what we teach.'),
          ],
        ),
        _Section(
          title: 'Why Learn Thai?',
          children: [
            _InfoBox(
                '🤝 Cultural respect — Thais are deeply touched when foreigners speak Thai\n\n💰 Better prices — vendors give you farang (foreigner) prices. Thai unlocks local prices.\n\n👫 Making friends — most locals don\'t speak much English. Thai opens doors.\n\n🛡️ Safety — knowing key phrases can get you out of trouble fast.'),
          ],
        ),
        _Section(
          title: 'Thai is Tonal',
          children: [
            _InfoBox(
                'Thai has 5 tones! The same syllable said with different tones means completely different things. Don\'t worry — context helps a lot, and Thais are patient and understanding.'),
            _TipBox(
                'Say "mai pen rai" (no worries) — even if your tones aren\'t perfect, Thais will understand and appreciate you trying!'),
          ],
        ),
        _Section(
          title: 'How This App Works',
          children: [
            _InfoBox(
                '📚 22 lessons in Stage 1 (Foundations)\n🏙️ 15 lessons in Stage 2 (Survival Thai)\n\nEach lesson has 10-12 vocabulary words with multiple exercise types. Earn 3 stars to unlock the next lesson.'),
            _TipBox('Tip: The "Review Mode" at the bottom of the home screen reinforces words you got wrong. Use it daily!'),
          ],
        ),
        _Section(
          title: 'Tips for Success',
          children: [
            _InfoBox(
                '⏰ Practice daily — even 5 minutes beats 1 hour once a week\n\n🎧 Listen to the audio every time — pronunciation is key\n\n🗣️ Use words with real Thai people as soon as you learn them\n\n😄 Don\'t fear mistakes — Thais LOVE when foreigners try Thai\n\n🧩 Context matters more than perfect pronunciation'),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 2 — Tones Guide
// ─────────────────────────────────────────────────────────────────────

class _TonesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const _Section(
          title: 'Thai has 5 Tones',
          children: [
            _InfoBox('Tones are crucial in Thai! The same syllable means completely different things depending on how you say it.'),
          ],
        ),
        const SizedBox(height: 8),
        ..._toneData.map((t) => _ToneCard(
              name: t[0],
              symbol: t[1],
              description: t[2],
              example: t[3],
              meaning: t[4],
            )),
        const _Section(
          title: 'The Magic of "maa"',
          children: [
            _CodeBox(
                'มา  (maa)  — mid tone     = to come\n'
                'ม้า  (máa)  — high tone    = horse\n'
                'หมา  (mǎa)  — rising tone  = dog\n'
                'ไม่  (mâi)  — falling tone = no/not\n'
                'ไม้  (mài)  — low tone     = wood'),
            _TipBox('When in doubt, use mid tone (flat, normal voice). Thais will understand from context!'),
          ],
        ),
        const _Section(
          title: 'Common Tone Mistakes',
          children: [
            _InfoBox(
                '⚠️  ไม่ (mai = no) vs ใหม่ (mai = new) — same sound, different tones\n\n'
                '⚠️  ข้าว (khao = rice) vs เขา (khao = he/she) — essential distinction!\n\n'
                '⚠️  สวย (suay) with right tone = beautiful... wrong tone = unlucky! 😅'),
          ],
        ),
      ],
    );
  }
}

const _toneData = [
  ['Mid tone', '—', 'Normal flat voice. No rise or fall.', 'maa (มา)', 'to come'],
  ['Low tone', '↘', 'Slightly lower than normal speech.', 'mài (ไม้)', 'wood'],
  ['Falling tone', '↘↘', 'Start high, fall sharply down.', 'mâi (ไม่)', 'not/no'],
  ['High tone', '↗', 'Start higher than normal, stay high.', 'máa (ม้า)', 'horse'],
  ['Rising tone', '↘↗', 'Dip down then rise up (like a question).', 'mǎa (หมา)', 'dog'],
];

class _ToneCard extends StatelessWidget {
  final String name, symbol, description, example, meaning;
  const _ToneCard({
    required this.name,
    required this.symbol,
    required this.description,
    required this.example,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(symbol,
                  style: const TextStyle(
                      fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                Text(description,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('$example — $meaning',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.thaiNavy,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 3 — Phonetic Guide
// ─────────────────────────────────────────────────────────────────────

class _PhoneticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const _Section(
          title: 'Reading Phonetics',
          children: [
            _InfoBox('This app uses simplified phonetic spelling (romanization). Here\'s how to read it:'),
          ],
        ),
        _Section(
          title: 'Consonant Sounds',
          children: [
            _tableSection('Sound', 'Like', 'Example', [
              ['ph', '"p" with air puff', 'phom = I (male)'],
              ['p', '"p" without air', 'bpai = go'],
              ['th', '"t" with air puff', 'thai = Thai'],
              ['t', '"t" without air', 'ton = now'],
              ['kh', '"k" with air puff', 'khun = you'],
              ['k', '"k" without air', 'kin = eat'],
              ['ng', 'singing (start of word!)', 'ngoo = snake'],
              ['dt', 'hard d/t sound', 'dtom = boil'],
              ['bp', 'hard b/p sound', 'bplaa = fish'],
              ['r', 'often said as "l"', 'rot = car'],
            ]),
          ],
        ),
        _Section(
          title: 'Vowel Sounds',
          children: [
            _tableSection('Written', 'Sound like', 'Example', [
              ['aa', 'father (long)', 'maa = come'],
              ['a', 'cat (short)', 'ja = will'],
              ['ee', 'see (long)', 'dee = good'],
              ['i', 'bit (short)', 'gin = eat'],
              ['oo', 'moon (long)', 'duu = watch'],
              ['u', 'put (short)', 'tuk = cheap'],
              ['oe', '"her" without r', 'ther = you'],
              ['ae', 'cat (longer)', 'maew = cat'],
              ['ao', '"cow"', 'khao = rice'],
              ['ia', '"ear"', 'rian = study'],
            ]),
          ],
        ),
        const _Section(
          title: 'Reading Practice',
          children: [
            _CodeBox(
                'สวัสดี  = sa + wat + dee  → "sa-wat-dee"\n'
                'ขอบคุณ  = khob + khun     → "khob-khun"\n'
                'ไม่เป็นไร = mai + pen + rai → "mai-pen-rai"\n'
                'อร่อย   = a + roi         → "a-roi"\n'
                'เท่าไหร่  = thao + rai     → "thao-rai"'),
            _TipBox('Words ending in "t" or "k" are clipped short — stop the sound abruptly!'),
          ],
        ),
      ],
    );
  }

  Widget _tableSection(String col1, String col2, String col3, List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.thaiNavy,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg - 1)),
            ),
            child: Row(
              children: [col1, col2, col3].map((h) => Expanded(
                child: Text(h,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              )).toList(),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: i.isEven ? AppTheme.surface : Colors.white,
              child: Row(
                children: row.map((cell) => Expanded(
                  child: Text(cell,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary)),
                )).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 4 — The Alphabet
// ─────────────────────────────────────────────────────────────────────

class _AlphabetTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: const [
        _Section(
          title: 'Thai Script Overview',
          children: [
            _InfoBox('Thai has 44 consonants, 32 vowels, and 4 tone marks. That sounds scary — but you don\'t need all of them to speak Thai!\n\nThis app focuses on spoken Thai with phonetics first. The alphabet is a bonus for advanced learners.'),
            _TipBox('Learn the 15 most common consonants first. That covers ~80% of everyday words!'),
          ],
        ),
        _Section(
          title: 'The 15 Most Common Consonants',
          children: [
            _CodeBox(
                'ก  g/k   — กไก่  (gai = chicken)\n'
                'ข  kh    — ขไข่  (khai = egg)\n'
                'ค  kh    — คควาย (low class)\n'
                'ง  ng    — งงู   (nguu = snake)\n'
                'จ  j     — จจาน  (jaan = plate)\n'
                'ช  ch    — ชช้าง  (chaang = elephant)\n'
                'ด  d     — ดเด็ก  (dek = child)\n'
                'ต  dt    — ตเต่า  (dtao = turtle)\n'
                'น  n     — นหนู   (nuu = mouse)\n'
                'ป  bp    — ปปลา   (bplaa = fish)\n'
                'พ  ph    — พพาน   (phaan = tray)\n'
                'ม  m     — มแมว   (maew = cat)\n'
                'ร  r     — รเรือ   (ruea = boat)\n'
                'ล  l     — ลลิง    (ling = monkey)\n'
                'ส  s     — สเสือ   (suea = tiger)'),
          ],
        ),
        _Section(
          title: 'Consonant Classes',
          children: [
            _InfoBox('Thai consonants are grouped into 3 classes (high, mid, low). This affects the tone of the syllable:\n\n🔴 High class — tends to raise the tone\n🟡 Mid class — neutral baseline\n🟢 Low class — tends to lower the tone\n\nDon\'t worry about memorizing this yet — just be aware it exists!'),
          ],
        ),
        _Section(
          title: 'Essential Vowels',
          children: [
            _CodeBox(
                'า   aa (long)    — มา  (maa = come)\n'
                'ิ   i (short)    — กิน  (gin = eat)\n'
                'ี   ii (long)    — ดี  (dii = good)\n'
                'ุ   u (short)    — กุ   (gu)\n'
                'ู   uu (long)    — ดู  (duu = watch)\n'
                'เ   ay/eh       — เก   (before consonant)\n'
                'แ   ae          — แมว (maew = cat)\n'
                'โ   oh          — โต  (doh = big)\n'
                'ไ   ai          — ไป  (bpai = go)\n'
                'ใ   ai          — ใจ  (jai = heart)'),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 5 — Survival Phrases
// ─────────────────────────────────────────────────────────────────────

class _SurvivalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const SizedBox(height: 16),
        const Text(
          'The 20 Most Important Phrases',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.thaiNavy),
        ),
        const SizedBox(height: 8),
        const Text(
          'Memorize these and you can survive anything in Bangkok',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        ..._survivalPhrases.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return _PhraseCard(
            number: i + 1,
            thai: p[0],
            phonetic: p[1],
            english: p[2],
            when: p[3],
          );
        }),
      ],
    );
  }
}

const _survivalPhrases = [
  ['สวัสดีครับ/ค่ะ', 'sa-wat-dee khrap/kha', 'Hello', 'Always — greeting anyone'],
  ['ขอบคุณครับ/ค่ะ', 'khob-khun khrap/kha', 'Thank you', 'Always — show gratitude'],
  ['ไม่เป็นไร', 'mai-pen-rai', 'No worries', 'Response to "sorry"'],
  ['เท่าไหร่', 'thao-rai', 'How much?', 'Shopping & eating'],
  ['ขอลดได้ไหม', 'khor-lot-dai-mai', 'Can you discount?', 'Markets & street stalls'],
  ['ไม่เผ็ด', 'mai-phet', 'Not spicy', 'Ordering food'],
  ['อร่อยมาก', 'a-roi-mak', 'Very delicious', 'Complimenting food'],
  ['ไปไหน', 'bpai-nai', 'Where going?', 'Taxis always ask this'],
  ['ที่ไหน', 'tee-nai', 'Where is...?', 'Finding anything'],
  ['ห้องน้ำอยู่ไหน', 'hong-naam-yuu-nai', 'Where is the bathroom?', 'ESSENTIAL!'],
  ['ช่วยด้วย', 'chuay-duay', 'Help me!', 'Emergency'],
  ['เรียกแท็กซี่', 'riak-taek-see', 'Call a taxi', 'Transport'],
  ['หยุดตรงนี้', 'yoot-trong-nee', 'Stop here', 'In a taxi'],
  ['ไม่เข้าใจ', 'mai-khao-jai', 'I don\'t understand', 'Confused? Say this'],
  ['พูดช้าๆได้ไหม', 'phuut-chaa-chaa-dai-mai', 'Speak slowly?', 'Learning Thai'],
  ['พูดภาษาอังกฤษได้ไหม', 'phuut-ang-krit-dai-mai', 'Can you speak English?', 'Emergency backup'],
  ['ราคารวมทุกอย่างไหม', 'raa-khaa-ruam-thuk-yang-mai', 'Is everything included?', 'Checking bills'],
  ['โทรหาตำรวจ', 'tho-haa-dtam-ruat', 'Call the police', 'Emergency'],
  ['ผมป่วย', 'pom-bpuay', 'I am sick', 'Hospital/pharmacy'],
  ['ขอบิลด้วย', 'khor-bin-duay', 'Bill please', 'Restaurants'],
];

class _PhraseCard extends StatelessWidget {
  final int number;
  final String thai, phonetic, english, when;

  const _PhraseCard({
    required this.number,
    required this.thai,
    required this.phonetic,
    required this.english,
    required this.when,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.thaiRed,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text('$number',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(thai,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.thaiNavy)),
                Text(phonetic,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic)),
                Text(english,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.thaiGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(when,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.thaiGold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab 6 — Culture Tips
// ─────────────────────────────────────────────────────────────────────

class _CultureTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        ..._cultureTips.map((t) => _Section(
              title: t[0],
              children: [_InfoBox(t[1])],
            )),
      ],
    );
  }
}

const _cultureTips = [
  ['The Wai 🙏', 'The wai is a prayer-like gesture with palms together. Who wais first? Younger/lower status person wais the elder/senior. Return a wai from anyone older. Don\'t wai children or service staff — a nod is fine.'],
  ['Head & Feet 👣', 'The head is sacred — never touch someone\'s head. Feet are considered low — never point your feet at people, Buddha images, or sacred objects. If sitting on the floor, tuck your feet behind you.'],
  ['The Royal Family 👑', 'Thailand has strict lèse-majesté laws. The Royal Family is deeply revered. Never criticize them. Always stand for the national anthem in cinemas and public spaces.'],
  ['Buddha Images 🪷', 'Buddha images are sacred objects, not photo props. Dress modestly at temples (cover shoulders and knees). Don\'t pose irreverently near Buddha images.'],
  ['Remove Shoes 👟', 'Always remove shoes before entering temples, many restaurants, and some homes and shops. If you see shoes at the entrance — take yours off too!'],
  ['Sanuk (สนุก) 😄', 'Thais highly value sanuk — fun and enjoyment. Keep things light and playful. Avoid showing anger in public (loss of face). "Jai yen" (cool heart) means staying calm and relaxed.'],
  ['Face (หน้า) 😊', 'Losing face is very serious in Thai culture. Don\'t embarrass Thais publicly — even if you\'re right. Find gentle ways to point out mistakes. Thais will often say yes when they mean no to save face.'],
  ['Bargaining 🛍️', 'Bargaining is normal and expected at markets, street stalls, and tuk-tuks. NOT in malls or 7-Eleven. Smile while bargaining — make it fun! Starting at 50-60% of the asking price is reasonable.'],
  ['Monks 🧘', 'Women cannot touch monks or hand things directly to them. Place items on a cloth for the monk to pick up. If you\'re a woman on public transport, do not sit next to a monk.'],
  ['Lucky Numbers 🔢', '9 is the luckiest number (sounds like "progress" in Thai). 6 is also lucky. License plates, house numbers, and phone numbers ending in 9s are highly sought after.'],
];
