package main

import (
	"log"
	"reflect"

	"golang.org/x/sys/windows/registry"
)

type SDSettings struct {
	BrowserPath       string `regName:"BrowserPath"`
	UseProfile        bool   `regName:"UseProfile"`
	EngineURL         string `regName:"EngineURL"`
	ProfileName       string `regName:"ProfileName"`
	InterfaceLanguage string `regName:"InterfaceLanguage"`
	SearchCount       uint   `regName:"SearchCount"`
	DisableNag        bool   `regName:"DisableNag"`
}

func (settings *SDSettings) LoadRegistry() {
	seValue := reflect.ValueOf(settings).Elem()

	sdKey, err := registry.OpenKey(registry.CURRENT_USER, "SOFTWARE\\Clients\\SearchDeflector", registry.READ)

	if err == nil {
		defer sdKey.Close()
	} else {
		log.Panicln("Could not open registry key for settings")
	}

	for i := 0; i < seValue.Type().NumField(); i++ {
		field := seValue.Type().Field(i)
		regName, ok := field.Tag.Lookup("regName")

		if !ok {
			log.Println("Could not find registry name for field " + field.Name)
			continue
		}

		_, valType, err := sdKey.GetValue(regName, nil)

		if err != nil {
			log.Panicln("Error reading expected registry value " + regName)
		}

		switch valType {
		case registry.NONE:
			log.Panicln("Registry type is NONE")
		case registry.SZ:
			value, _, _ := sdKey.GetStringValue(regName)
			seValue.FieldByName(regName).SetString(value)
		case registry.EXPAND_SZ:
			// todo
		case registry.BINARY:
		case registry.DWORD:
		case registry.DWORD_BIG_ENDIAN:
		case registry.LINK:
		case registry.MULTI_SZ:
		case registry.RESOURCE_LIST:
		case registry.FULL_RESOURCE_DESCRIPTOR:
		case registry.RESOURCE_REQUIREMENTS_LIST:
		case registry.QWORD:
		}
	}
}

func main() {
	settings := new(SDSettings)

	settings.LoadRegistry()

	log.Println(settings)
}
