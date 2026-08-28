//! Update lanes and optional asset policy (SPEC-020-R02, SPEC-020-R08).
//!
//! Core app, provider adapter, context rules, command pack, plugin pack,
//! renderer pack, audio pack, local model asset, and help index are separate
//! update lanes. Package, model, audio, renderer, help, and provider assets
//! are optional and never silently bundled or enabled.

use serde::{Deserialize, Serialize};

/// A distinct update lane.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum UpdateLane {
    CoreApp,
    ProviderAdapter,
    ContextRules,
    CommandPack,
    PluginPack,
    RendererPack,
    AudioPack,
    LocalModelAsset,
    HelpIndex,
}

impl UpdateLane {
    pub fn all() -> [UpdateLane; 9] {
        [
            UpdateLane::CoreApp,
            UpdateLane::ProviderAdapter,
            UpdateLane::ContextRules,
            UpdateLane::CommandPack,
            UpdateLane::PluginPack,
            UpdateLane::RendererPack,
            UpdateLane::AudioPack,
            UpdateLane::LocalModelAsset,
            UpdateLane::HelpIndex,
        ]
    }

    pub fn as_str(self) -> &'static str {
        match self {
            UpdateLane::CoreApp => "core-app",
            UpdateLane::ProviderAdapter => "provider-adapter",
            UpdateLane::ContextRules => "context-rules",
            UpdateLane::CommandPack => "command-pack",
            UpdateLane::PluginPack => "plugin-pack",
            UpdateLane::RendererPack => "renderer-pack",
            UpdateLane::AudioPack => "audio-pack",
            UpdateLane::LocalModelAsset => "local-model-asset",
            UpdateLane::HelpIndex => "help-index",
        }
    }

    /// SPEC-020-R08: optional asset lanes must never be silently enabled.
    pub fn is_optional_asset(self) -> bool {
        !matches!(self, UpdateLane::CoreApp)
    }
}

/// A lane's enablement state with an explicit consent record.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LaneState {
    pub lane: UpdateLane,
    pub enabled: bool,
    /// The explicit user consent that enabled the lane; empty when disabled.
    pub consent: String,
}

/// The lane policy evaluator.
pub struct LanePolicy;

impl LanePolicy {
    /// Every optional lane must have explicit consent when enabled.
    pub fn optional_lanes_require_consent(states: &[LaneState]) -> bool {
        states
            .iter()
            .filter(|s| s.lane.is_optional_asset() && s.enabled)
            .all(|s| !s.consent.is_empty())
    }

    /// Core app is always present; optional lanes default disabled.
    pub fn default_lane_states() -> Vec<LaneState> {
        UpdateLane::all()
            .iter()
            .map(|lane| LaneState {
                lane: *lane,
                enabled: matches!(lane, UpdateLane::CoreApp),
                consent: String::new(),
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nine_separate_lanes() {
        assert_eq!(UpdateLane::all().len(), 9);
    }

    #[test]
    fn core_app_is_not_optional() {
        assert!(!UpdateLane::CoreApp.is_optional_asset());
        assert!(UpdateLane::AudioPack.is_optional_asset());
        assert!(UpdateLane::LocalModelAsset.is_optional_asset());
    }

    #[test]
    fn enabled_optional_lane_needs_consent() {
        let states = vec![
            LaneState {
                lane: UpdateLane::CoreApp,
                enabled: true,
                consent: String::new(),
            },
            LaneState {
                lane: UpdateLane::AudioPack,
                enabled: true,
                consent: "user-approved-2026-08".to_string(),
            },
        ];
        assert!(LanePolicy::optional_lanes_require_consent(&states));
    }

    #[test]
    fn silently_enabled_optional_lane_fails() {
        let states = vec![LaneState {
            lane: UpdateLane::PluginPack,
            enabled: true,
            consent: String::new(),
        }];
        assert!(!LanePolicy::optional_lanes_require_consent(&states));
    }

    #[test]
    fn defaults_disable_optional_lanes() {
        let states = LanePolicy::default_lane_states();
        assert!(states
            .iter()
            .all(|s| s.lane == UpdateLane::CoreApp || !s.enabled));
    }
}
