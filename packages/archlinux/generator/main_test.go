// Copyright Mondoo, Inc. 2025, 2026
// SPDX-License-Identifier: BUSL-1.1

package main

import (
	"strings"
	"testing"
)

func TestRenderPkgBuildSeparatesArrayValues(t *testing.T) {
	var out strings.Builder
	err := renderPkgBuild(PkgBuild{
		Product: Product{
			PkgName:   "mondoo",
			License:   "custom",
			Depends:   []string{"cnspec", "mql"},
			Conflicts: []string{"cnquery", "legacy-mondoo"},
			Replaces:  []string{"cnquery", "legacy-mondoo"},
		},
		Version: "13.11.0",
	}, &out)
	if err != nil {
		t.Fatalf("renderPkgBuild() error = %v", err)
	}

	rendered := out.String()
	for _, want := range []string{
		"depends=('cnspec' 'mql')",
		"conflicts=('cnquery' 'legacy-mondoo')",
		"replaces=('cnquery' 'legacy-mondoo')",
	} {
		if !strings.Contains(rendered, want) {
			t.Fatalf("rendered PKGBUILD does not contain %q:\n%s", want, rendered)
		}
	}
}

func TestRenderPkgBuildEscapesArrayValues(t *testing.T) {
	if got, want := pkgbuildArray([]string{"normal", "contains'quote"}), "'normal' 'contains'\"'\"'quote'"; got != want {
		t.Fatalf("pkgbuildArray() = %q, want %q", got, want)
	}
}

func TestRenderPkgBuildSeparatesConflictsAndReplaces(t *testing.T) {
	tests := []struct {
		name     string
		product  Product
		want     string
		dontWant string
	}{
		{
			name: "conflicts without replaces",
			product: Product{
				PkgName:   "mondoo",
				License:   "custom",
				Conflicts: []string{"cnquery"},
			},
			want:     "conflicts=('cnquery')",
			dontWant: "replaces=",
		},
		{
			name: "replaces without conflicts",
			product: Product{
				PkgName:  "mondoo",
				License:  "custom",
				Replaces: []string{"cnquery"},
			},
			want:     "replaces=('cnquery')",
			dontWant: "conflicts=",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			var out strings.Builder
			err := renderPkgBuild(PkgBuild{
				Product: test.product,
				Version: "13.11.0",
			}, &out)
			if err != nil {
				t.Fatalf("renderPkgBuild() error = %v", err)
			}

			rendered := out.String()
			if !strings.Contains(rendered, test.want) {
				t.Fatalf("rendered PKGBUILD does not contain %q:\n%s", test.want, rendered)
			}
			if strings.Contains(rendered, test.dontWant) {
				t.Fatalf("rendered PKGBUILD unexpectedly contains %q:\n%s", test.dontWant, rendered)
			}
		})
	}
}

func TestRenderSrcInfoIncludesDependencies(t *testing.T) {
	var out strings.Builder
	err := renderScrInfo(PkgBuild{
		Product: Product{
			PkgName: "mondoo",
			License: "custom",
			Depends: []string{"cnspec", "mql"},
			ExtraFiles: []SourceFile{
				{Name: "mondoo.sh"},
			},
		},
		Version: "13.11.0",
	}, &out)
	if err != nil {
		t.Fatalf("renderScrInfo() error = %v", err)
	}

	rendered := out.String()
	for _, want := range []string{
		"depends = cnspec",
		"depends = mql",
		"source = mondoo.sh",
	} {
		if !strings.Contains(rendered, want) {
			t.Fatalf("rendered .SRCINFO does not contain %q:\n%s", want, rendered)
		}
	}

	if strings.Contains(rendered, "mondoo_13.11.0_linux_amd64.tar.gz") {
		t.Fatalf("rendered .SRCINFO contains binary source for non-binary package:\n%s", rendered)
	}
}
