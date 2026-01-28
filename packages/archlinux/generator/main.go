// Copyright Mondoo, Inc. 2026, 2025, 0
// SPDX-License-Identifier: BUSL-1.1

package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"text/template"
)

type SourceFile struct {
	Name        string
	Permissions string
	Destination string
}

type Product struct {
	LatestUrl   string
	Description string
	Homepage    string
	PkgName     string
	Class       string
	License     string
	ExtraFiles  []SourceFile
	BinFile     bool
	IncludeOpt  bool
	Depends     []string
}

var products = map[string]Product{
	"mondoo": {
		LatestUrl:   "https://releases.mondoo.com/mondoo/latest.json?ignoreCache=1",
		Description: "Mondoo Client CLI for the Mondoo Policy as Code Platform",
		Homepage:    "https://mondoo.com",
		PkgName:     "mondoo",
		Class:       "Mondoo",
		License:     "custom",
		ExtraFiles: []SourceFile{
			{
				Name:        "LICENSE.html",
				Permissions: "644",
				Destination: "/usr/share/licenses/$pkgname/LICENSE.html",
			},
			{
				Name:        "OSS-LICENSES.tar.xz",
				Permissions: "644",
				Destination: "/usr/share/licenses/$pkgname/OSS-LICENSES.tar.xz",
			},
			{
				Name:        "mondoo.service",
				Permissions: "644",
				Destination: "/usr/lib/systemd/system/mondoo.service",
			},
			{
				Name:        "mondoo.sh",
				Permissions: "755",
				Destination: "/usr/bin/mondoo",
			},
		},
		IncludeOpt: true,
		BinFile:    false,
		Depends: []string{
			"cnspec",
		},
	},
	"cnquery": {
		LatestUrl:   "https://releases.mondoo.com/cnquery/latest.json?ignoreCache=1",
		Description: "Cloud-Native Query - Asset Inventory Framework",
		Homepage:    "https://mondoo.com",
		PkgName:     "cnquery",
		Class:       "Cnquery",
		License:     "BUSL-1.1",
		BinFile:     true,
	},
	"cnspec": {
		LatestUrl:   "https://releases.mondoo.com/cnspec/latest.json?ignoreCache=1",
		Description: "Cloud-Native Security and Policy Framework ",
		Homepage:    "https://mondoo.com",
		PkgName:     "cnspec",
		Class:       "Cnspec",
		License:     "BUSL-1.1",
		BinFile:     true,
		Depends: []string{
			"cnquery",
		},
	},
}

// Usage: go run main.go
// Example: go run generator/main.go cnquery /path
func main() {
	if len(os.Args) != 3 {
		panic("need argument for product and path")
	}

	productName := os.Args[1]
	path := os.Args[2]
	product, ok := products[productName]
	if !ok {
		panic("product not found")
	}

	latest, err := fetchLatest(product.LatestUrl)
	if err != nil {
		log.Fatal(err)
	}

	versionMatcher := regexp.MustCompile(product.PkgName + `\/(\d+.\d+.\d+(?:[-\d\w]+)?)\/` + product.PkgName)

	// filter by linux and amd64
	pb := PkgBuild{
		Product: product,
	}

	for i := range latest.Files {
		f := latest.Files[i]

		m := versionMatcher.FindStringSubmatch(f.Filename)
		if len(m) == 2 {
			pb.Version = m[1]
		}

		if f.Platform == "linux" && strings.HasSuffix(f.Filename, "amd64.tar.gz") {
			pb.Sha256 = f.Hash
		}
	}

	for _, sf := range product.ExtraFiles {
		data, err := os.ReadFile(path + "/" + sf.Name)
		if err != nil {
			panic(err)
		}
		hashBytes := sha256.Sum256(data)
		hash := hex.EncodeToString(hashBytes[:])
		pb.ExtraSha256 = append(pb.ExtraSha256, hash)
	}

	// write PKGBUILD
	buf := new(bytes.Buffer)
	err = renderPkgBuild(pb, buf)
	if err != nil {
		panic(err)
	}

	err = os.WriteFile(path+"/PKGBUILD", buf.Bytes(), 0644)
	if err != nil {
		panic(err)
	}

	// write .SRCINFO
	buf2 := new(bytes.Buffer)
	err = renderScrInfo(pb, buf2)
	if err != nil {
		panic(err)
	}

	err = os.WriteFile(path+"/.SRCINFO", buf2.Bytes(), 0644)
	if err != nil {
		panic(err)
	}

	os.Exit(0)
}

type Latest struct {
	Files []File `json:"files"`
}

type File struct {
	Filename string `json:"filename"`
	Size     int    `json:"size"`
	Platform string `json:"platform"`
	Hash     string `json:"hash"`
}

func fetchLatest(latestUrl string) (*Latest, error) {
	resp, err := http.Get(latestUrl)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var latest Latest
	if err := json.Unmarshal(data, &latest); err != nil {
		return nil, err
	}

	return &latest, nil
}

type PkgBuild struct {
	Product
	Version     string
	Sha256      string
	ExtraSha256 []string
}

var pkgBuildTemplate = `# Maintainer: Mondoo Inc <hello@mondoo.com>
# Maintainer: Dominik Richter <dom@mondoo.com>
# Maintainer: Patrick Münch <patrick@mondoo.com>
#
pkgname={{ .PkgName }}
orignalVersion="{{ .Version }}"
pkgver="${orignalVersion/-/_}"
pkgrel=1
pkgdesc="{{ .Description }}"
url="https://mondoo.com"
license=('{{ .License }}')
source=(
    {{- if .BinFile }}"https://releases.mondoo.com/{{ .PkgName }}/${orignalVersion}/{{ .PkgName }}_${orignalVersion}_linux_amd64.tar.gz"{{- end }}
    {{ range .ExtraFiles -}}
    '{{ .Name }}'
    {{ end -}}
)
arch=('x86_64')
depends=({{ range .Depends }}'{{ . }}'{{ end }})

sha256sums=({{- if .BinFile }}'{{ .Sha256 }}'{{- end }}
            {{ range .ExtraSha256 -}}
            '{{ . }}'
            {{ end -}}
)


package() {
  {{- if .BinFile }}
  install -dm755 ${pkgdir}/usr/bin
  cp ${srcdir}/$pkgname ${pkgdir}/usr/bin/.
  {{- end }}

  {{ range .ExtraFiles -}}
  install -Dm {{ .Permissions }} {{ .Name }} "$pkgdir"{{- .Destination }}
  {{ end }}
}

#vim: syntax=sh`

func renderPkgBuild(b PkgBuild, out io.Writer) error {
	t := template.Must(template.New("formula").Parse(pkgBuildTemplate))
	return t.Execute(out, b)
}

var pkgSourceInfoTemplate = `pkgbase = {{ .PkgName }}
pkgdesc = {{ .Description }}
pkgver = {{ .Version }}
pkgrel = 1
url = https://mondoo.com
arch = x86_64
license = {{ .License }}
source = https://releases.mondoo.com/{{ .PkgName }}/{{ .Version }}/{{ .PkgName }}_{{ .Version }}_linux_amd64.tar.gz
{{ range .ExtraFiles -}}
source = {{ .Name }}
{{ end }}
sha256sums = {{ .Sha256 }}
{{ range .ExtraSha256 -}}
sha256sums = {{ . }}
{{ end }}

pkgname = {{ .PkgName }}
`

func renderScrInfo(b PkgBuild, out io.Writer) error {
	t := template.Must(template.New("formula").Parse(pkgSourceInfoTemplate))
	return t.Execute(out, b)
}
