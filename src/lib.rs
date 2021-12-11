pub mod registry {
    use std::collections::HashMap;
    use std::error::Error;
    use winapi::shared::minwindef::HKEY;
    use winreg::{
        enums::{
            HKEY_CURRENT_USER,
            HKEY_LOCAL_MACHINE,
        },
        RegKey,
    };

    /// Get a map of browser names and executables currently installed on the system.
    /// Parameter `hive` determines where to look, either `HKEY_CURRENT_USER` or `HKEY_LOCAL_MACHINE`.
    /// If `hive` is `None`, results from both hives will be returned.
    pub fn get_installed_browsers(hive: Option<HKEY>) -> Result<HashMap<String, String>, Box<dyn Error>> {
        match hive {
            Some(HKEY_CURRENT_USER) | Some(HKEY_LOCAL_MACHINE) => {
                let kain_key = RegKey::predef(hive.unwrap()).open_subkey("SOFTWARE\\Clients\\StartMenuInternet")?;

                let mut browsers: HashMap<String, String> = HashMap::new();

                for browser_key in kain_key.enum_keys() {
                    let browser_key = kain_key.open_subkey(browser_key?)?;
                    let name = browser_key.get_value("")?;
                    let executable = browser_key.open_subkey("shell\\open\\command")?.get_value("")?;

                    browsers.insert(name, executable);
                }

                Ok(browsers)
            },
            None => {
                let mut browsers = get_installed_browsers(Some(HKEY_CURRENT_USER))?;
                browsers.extend(get_installed_browsers(Some(HKEY_LOCAL_MACHINE))?);

                Ok(browsers)
            },
            _ => {
                Err("parameter `hive` should have been either `HKEY_CURRENT_USER` or `HKEY_LOCAL_MACHINE`".into())
            },
        }
    }
}

pub mod simple_parser {
    use std::collections::HashMap;
    use std::error::Error;
    use std::fs::File;
    use std::io::BufReader;
    use std::path::Path;

    pub fn parse_config<T: AsRef<str>>(path: T) -> Result<HashMap<String, Option<String>>, Box<dyn Error>>{
        let reader = BufReader::new(File::open(Path::new(path))?);
        let mut result = HashMap::new();

        for line in reader.lines() {
            let line = line?.trim();

            if line.is_empty() || line.starts_with("//") {
                continue
            }

            if let Some((key, value)) = line.split_once(":") {
                let (key, value) = (key.strip(), value.strip());

                if value.is_empty() {
                    result.insert(key, None);
                } else {
                    result.insert(key, Some(value));
                }
            } else {
                Err("a line that was not a comment had no pair delimiter".into())
            }
        }

        Ok(result)
    }
}
