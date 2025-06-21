# Migration Guide: `active_record_compose` 0.8.x to 0.9.0+

⚠️ **Breaking Change**

This guide explains how to migrate from version **0.8.x** to **0.9.0 or later**, assuming that your codebase includes:

```ruby
self.persisted_flag_callback_control = false
```

This setting was officially **deprecated** in 0.9.0 and is **no longer supported**. Migration is required to adopt the current default behavior.

## Background

In version **0.7.x**, the default value of `persisted_flag_callback_control` was `false`.

In **0.8.x**, the default was changed to `true`.
If you are still using `false` in your models, it means you have **explicitly overridden the default**, likely to preserve backward-compatible behavior.

This guide helps you safely migrate to the new behavior while preserving intended callback semantics.

## Goal of the Migration

- Remove any use of `persisted_flag_callback_control = false`
- Adjust callback definitions to align with the semantics of `#persisted?`

## Step 1 – Remove Deprecated Flag

Find and remove all instances of:

```diff
-self.persisted_flag_callback_control = false
```

## Step 2 – Understand Callback Behavior Changes

With `persisted_flag_callback_control = true`, whether a callback is fired depends on the return value of `#persisted?`, not the method used (`create` or `update`).

### When saving with `#update`:

If `persisted?` returns `false`, then:

- `before_update`
- `after_update`
- `around_update`

will **not** be triggered.

✅ Recommended fix:

If you don’t differentiate between creation and update phases, switch to `*_save` callbacks:

```diff
- before_update :track_change
+ before_save :track_change
```

### When saving with `#create`:

If `persisted?` returns `true`, then:

- `before_create`
- `after_create`
- `around_create`

will **not** be triggered.

✅ Recommended fix:

Again, prefer `*_save` if you're using shared logic across creation and update:

```diff
- after_create :send_notification
+ after_save :send_notification
```

## Step 3 – Override `#persisted?` if Needed

If your composed model wraps an ActiveRecord instance and delegates its persistence logic, be sure to override `#persisted?` to reflect the correct state:

```ruby
class Foo < ActiveRecordCompose::Model
  def initialize(bar = Bar.new)
    super()
    @bar = bar
  end

  def persisted? = bar.persisted?

  private

  attr_reader :bar
end
```

## Migration Checklist ✅

- [ ] All models now `persisted_flag_callback_control` omit it entirely
- [ ] All callback definitions have been reviewed and updated
- [ ] Any `*_create` or `*_update` callbacks have been replaced with `*_save` where applicable
- [ ] `#persisted?` is correctly overridden where needed
- [ ] All tests pass and expected callbacks are fired

## Why This Change?

By aligning callback behavior with `persisted?`, you gain:

- Clearer intent and semantics
- More accurate behavior when composing or wrapping persisted models
- Improved compatibility with Rails conventions
- Less surprising callback triggering

If you have questions or run into edge cases, feel free to [open an issue](https://github.com/hamajyotan/active_record_compose/issues) or start a discussion.
