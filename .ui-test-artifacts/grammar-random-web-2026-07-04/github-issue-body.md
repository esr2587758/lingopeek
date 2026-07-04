# 语法解析随机长句 QA 结果

使用当前仓库构建的 LingoPeek Grammar view，对 10 个从公开网页随机抽取的英文长句进行语法解析检查。按用户要求，不记录网页 URL 和网页截图；证据集中在句子、LingoPeek 截图、本次判断说明。

## 发现

- S2：关系从句内部并列成分被提升成顶层并列宾语。
- S4：语法动作结构化失败，显示 `AI 返回结构不符合语法面板，请重试。`
- S9：第二个并列谓语 `has since been widely regarded` 被标成状语。

## 运行环境

- 日期：2026-07-04
- App：当前仓库 debug binary `.build/arm64-apple-macosx/debug/LingoPeek`
- 触发方式：`LINGOPEEK_UI_TEST_SELECTION` + `LINGOPEEK_UI_TEST_BYPASS_SETUP=1`
- 截图 artifact 根目录：`.ui-test-artifacts/grammar-random-web-2026-07-04/`
- 说明：`gh issue create` 不能直接上传本地 PNG 附件；截图以本地 artifact 路径记录。

## 逐句证据

### S1

句子：In addition to the usual marriage intended for raising families, the Twelver branch of Shia Islam permits zawāj al-mut'ah or "temporary", fixed-term marriage; and some Sunni Islamic scholars permit nikah misyar marriage, which lacks some conditions such as living together.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-01.png`

运行状态：AI 完成 (complete, 9.2s)

结论：未发现可见内容错误

说明：成分标注把让步/补充介词短语、两个并列主谓宾结构、以及 which 定语从句拆分得基本可接受。

### S2

句子：The Auckland region of New Zealand is built on a basement of greywacke rocks that form many of the islands in the Hauraki Gulf, the Hunua Ranges, and land south of Port Waikato.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-02.png`

运行状态：AI 完成 (complete, 8.5s)

结论：Bug: 关系从句内部并列成分被提升成顶层并列宾语

说明：LingoPeek 将 `that form many of the islands in the Hauraki Gulf` 标为定语后，又把 `the Hunua Ranges` 和 `and land south of Port Waikato` 标成并列宾语。它们其实属于 `that form ...` 关系从句内部，和 `many of the islands in the Hauraki Gulf` 共同构成 form 的宾语/并列对象，不应成为主句 `is built on` 的顶层宾语。

### S3

句子：The 26th Billboard Latin Music Awards ceremony, presented by Billboard magazine, honored the best performing Latin recordings of 2018 and took place on April 25, 2019 at the Mandalay Bay Events Center in Las Vegas.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-03.png`

运行状态：AI 完成 (complete, 8.1s)

结论：未发现可见内容错误

说明：成分标注将 `presented by Billboard magazine` 作为后置定语/分词短语，并识别 `honored ... and took place ...` 的并列谓语，基本可接受。

### S4

句子：Concerns over Chinese involvement in 5G wireless networks stem from allegations that cellular network equipment sourced from vendors from the People's Republic of China may contain backdoors enabling surveillance by the Chinese government (as part of its intelligence activity internationally) and Chinese laws, such as the Cybersecurity Law of the People's Republic of China, which compel companies and individuals to assist the state intelligence agency on the collection of information whenever requested.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-04.png`

运行状态：格式错误 (failure, 15.3s)

结论：Bug: 语法动作结构化失败

说明：该长句触发错误面板：`AI 返回结构不符合语法面板，请重试。` 这不是一个具体成分误判，但会阻断 Grammar view 对真实长句的语法解析。

### S5

句子：In parecon, self-management constitutes a replacement for the mainstream conception of economic freedom, which Albert and Hahnel argue by its very vagueness has allowed it to be abused by capitalist ideologues.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-05.png`

运行状态：AI 完成 (complete, 8.9s)

结论：未发现明确可见内容错误

说明：可见成分对 `which Albert and Hahnel argue ... has allowed ...` 的嵌套关系表达较粗，但没有足够证据判定为客观语法错误。

### S6

句子：Latin gamma is used to represent a voiced velar fricative, in the International Phonetic Alphabet, and in the alphabets of several African languages such as Yom, Dagbani, Dinka, Kabiyé, and Ewe, some Berber languages using the Berber Latin alphabet, and sometimes in the romanization of Pashto.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-06.png`

运行状态：AI 完成 (complete, 9.0s)

结论：未发现可见内容错误

说明：被动谓语 `is used to represent`、宾语和后续多个介词短语/并列连接的可见拆分基本可接受。

### S7

句子：The town is called the Balcony of Sicily for its panoramic position, with views over the valley of the Ippari and its towns (Comiso, Vittoria, Acate) all the way to the Mediterranean Sea to the south, as far as Mount Etna to the north, and the Erean Mountains with Caltagirone to the west.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-07.png`

运行状态：AI 完成 (complete, 8.9s)

结论：未发现可见内容错误

说明：主语、被动谓语、原因状语、伴随/范围状语拆分基本可接受。

### S8

句子：Besides the batteries, the battery commander's station still stands; in addition, a flagpole has been erected as a memorial to the intelligence officers who served at the fort during World War II.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-08.png`

运行状态：AI 完成 (complete, 8.4s)

结论：未发现可见内容错误

说明：分号连接的两个独立分句、第二分句被动谓语、以及 `who served ...` 定语从句可见拆分基本可接受。

### S9

句子：Despite an initial positive reception in Europe, the series was panned by critics, viewers, and longtime fans for its animation, writing, and deviations from its predecessor, and has since been widely regarded as one of the worst animated series ever made.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-09.png`

运行状态：AI 完成 (complete, 11.3s)

结论：Bug: 第二个并列谓语被标成状语

说明：LingoPeek 将 `has since been widely regarded` 标成绿色状语。它应是与 `was panned` 并列、共享主语 `the series` 的第二个被动谓语；`as one of the worst animated series ever made` 才是该谓语的补足/表语成分。

### S10

句子：Fairfield Halls is an arts, entertainment and conference centre in Croydon, London, England, which opened in 1962 and contains a theatre and gallery, and a large concert hall regularly used for BBC television, radio and orchestral recordings.

截图：`.ui-test-artifacts/grammar-random-web-2026-07-04/lingopeek-10.png`

运行状态：AI 完成 (complete, 9.9s)

结论：未发现可见内容错误

说明：主系表结构、地点修饰、which 定语从句内部 `opened ... and contains ...` 的可见拆分基本可接受。

## 期望

- Grammar view 不应把关系从句内部的并列宾语提升成主句级成分。
- Grammar view 不应把完整的并列谓语动词短语标成状语。
- 对真实长句的 AI JSON 结构化结果应能稳定进入语法面板，或提供可恢复的重试路径并记录足够诊断信息。

## 后续建议

- 增加包含 S2/S9 的回归 fixture，断言 chunk role 与层级关系。
- 增加 S4 的结构化解码回归，确认 staged grammar prompts 的长句输出不会落入 `格式错误`。