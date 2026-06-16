# Use OpenAI-compatible AI settings

Lingobar MVP should expose AI configuration as OpenAI-compatible settings rather than a DeepSeek-specific product surface. DeepSeek can remain the default base URL and model, but the app should store and present the provider configuration as API token, base URL, and model so the self-use MVP can switch compatible providers without changing the product model.

**Considered Options**

- DeepSeek-specific settings: rejected because it would hard-code a current default provider into the product language.
- OpenAI-compatible settings with DeepSeek defaults: accepted because it preserves the current implementation path while keeping provider choice flexible.
