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

func LoadRegistry(kData interface{}, k registry.Key, path string) {
	kdValue := reflect.ValueOf(kData).Elem()

	rKey, err := registry.OpenKey(k, path, registry.READ)

	if err == nil {
		defer rKey.Close()
	} else {
		log.Panicf("Could not open key %#v with path %q", k, path)
	}

	for i := 0; i < kdValue.Type().NumField(); i++ {
		field := kdValue.Type().Field(i)
		log.Println(field)

		regName, ok := field.Tag.Lookup("regName")

		if !ok {
			log.Printf("Required 'regName' tag missing for field %q", field.Name)
			continue
		}

		_, valType, err := rKey.GetValue(regName, nil)

		if err != nil {
			log.Panicln("Error getting value for %q with 'regName' %q", field.Name, regName)
		}

		switch valType {
		case registry.NONE:
			log.Panicln("Registry type is NONE")
		case registry.SZ:
			value, _, _ := rKey.GetStringValue(regName)
			kdValue.FieldByName(field.Name).SetString(value)
		case registry.EXPAND_SZ:
			// todo
		case registry.BINARY:
		case registry.DWORD:
			value, _, _ := rKey.GetIntegerValue(regName)
			kdValue.FieldByName(field.Name).SetInt(int64(value))
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

	LoadRegistry(settings, registry.CURRENT_USER, "SOFTWARE\\Clients\\SearchDeflector")

	log.Println(settings)
}
