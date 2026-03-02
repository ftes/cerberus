---
# cerberus-ql0l
title: Support assert_download across live static and browser
status: todo
type: feature
created_at: 2026-03-02T19:56:54Z
updated_at: 2026-03-02T19:56:54Z
---

Goal: support assert_download consistently across live, static, and browser drivers.\n\nScope:\n- [ ] Define public assert_download API semantics and callback contract shared by all drivers\n- [ ] Implement assert_download for static and live drivers\n- [ ] Ensure browser assert_download behavior matches shared semantics\n- [ ] Add cross-driver tests in test/cerberus that verify parity\n- [ ] Update docs with examples and driver notes
