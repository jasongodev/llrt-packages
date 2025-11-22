#!/bin/bash
set -e

update_package() {
  set -e
    local dir="$1"
      pkgdir=$(realpath "$dir")
      pkgname=$(basename "$pkgdir")
      echo -e "\n\e[1;34m==>\e[0m Updating aur/$pkgname"
      cd "$pkgdir" || exit 1

      shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164,SC2148,SC2128 PKGBUILD && echo "✅ PKGBUILD has valid bash syntax" || (echo "❌ PKGBUILD issues found"; exit 1)
      namcap PKGBUILD && echo "✅ PKGBUILD has valid format" || (echo "❌ PKGBUILD issues found"; exit 1)

      tmpdir=$(mktemp -d)
      cp -r ./ "$tmpdir" 
      cd "$tmpdir" || exit 1
      pkgctl version upgrade 2>&1 | grep -E "upgraded from|is latest" | xargs -rI{} echo "✅ pkgctl:" {}
      cp "$tmpdir/PKGBUILD" "$pkgdir/PKGBUILD"
      rm -rf "$tmpdir"

      
      cd "$pkgdir" || exit 1
      makepkg --printsrcinfo > .SRCINFO && echo "✅ .SRCINFO updated" || (echo "❌ Error updating .SRCINFO"; exit 1)

      git add . > /dev/null 2>&1 || true
      git commit -m "Version bump" > /dev/null 2>&1 || true

      git remote remove origin || true
      git remote add origin "https://github.com/jasongodev/aur-$pkgname.git"
      
      git remote remove aur || true
      git remote add aur "ssh://aur@aur.archlinux.org/$pkgname.git"

      OUT=$(git push -u origin master 2>&1) && echo "✅ Package pushed to GitHub" || (echo "❌ Error pushing to GitHub: $OUT")
      OUT=$(git push -u aur master 2>&1) && echo "✅ Package pushed to AUR" || (echo "❌ Error pushing to AUR: $OUT")
}

echo "Updating AUR packages"
export -f update_package
for dir in ./*/ ; do
  sem -j +0 "update_package $dir"
done
sem --wait