//! # lorri
//! lorri is a wrapper over Nix to abstract project-specific build
//! configuration and patterns in to a declarative configuration.

#![warn(missing_docs)]

#[macro_use]
extern crate structopt;

#[macro_use]
extern crate log;
extern crate env_logger;

extern crate regex;
#[macro_use]
extern crate lazy_static;

extern crate serde;
#[macro_use]
extern crate serde_derive;
extern crate serde_json;

extern crate notify;
extern crate tempfile;
extern crate vec1;

extern crate proptest;

pub mod bash;
pub mod build_loop;
pub mod builder;
pub mod cas;
pub mod changelog;
pub mod cli;
pub mod constants;
pub mod daemon;
pub mod locate_file;
pub mod logging;
pub mod mpsc;
pub mod nix;
pub mod ops;
pub mod osstrlines;
pub mod pathreduction;
pub mod project;
pub mod socket;
pub mod thread;
pub mod watch;

use std::path::{Path, PathBuf};

// OUT_DIR and build_rev.rs are generated by cargo, see ../build.rs
include!(concat!(env!("OUT_DIR"), "/build_rev.rs"));

/// A .nix file.
///
/// Is guaranteed to have an absolute path by construction.
#[derive(Hash, PartialEq, Eq, Clone, Debug, Serialize, Deserialize)]
pub struct NixFile(AbsPathBuf);

/// Path guaranteed to be absolute by construction.
#[derive(Hash, PartialEq, Eq, Clone, Debug, Serialize, Deserialize)]
pub struct AbsPathBuf(PathBuf);

impl AbsPathBuf {
    /// Convert from a known absolute path.
    ///
    /// Passing a relative path is a programming bug (unchecked).
    pub fn new_unchecked(path: PathBuf) -> Self {
        AbsPathBuf(path)
    }

    /// The absolute path, as `&Path`.
    pub fn as_absolute_path(&self) -> &Path {
        &self.0
    }

    /// Proxy through the `Display` class for `PathBuf`.
    pub fn display(&self) -> std::path::Display {
        self.0.display()
    }
}

impl NixFile {
    /// Absolute path of this file.
    pub fn as_absolute_path(&self) -> &Path {
        &self.0.as_absolute_path()
    }
}

impl From<AbsPathBuf> for NixFile {
    fn from(abs_path: AbsPathBuf) -> Self {
        NixFile(abs_path)
    }
}

/// Proxy through the `Display` class for `AbsPathBuf`.
impl std::fmt::Display for NixFile {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        self.0.display().fmt(f)
    }
}

/// A .drv file (generated by `nix-instantiate`).
#[derive(Hash, PartialEq, Eq, Clone, Debug)]
pub struct DrvFile(PathBuf);

impl DrvFile {
    /// Underlying `Path`.
    pub fn as_path(&self) -> &Path {
        self.0.as_ref()
    }
}

impl From<PathBuf> for DrvFile {
    fn from(p: PathBuf) -> DrvFile {
        DrvFile(p)
    }
}
