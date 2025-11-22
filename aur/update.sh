#!/bin/bash
set -e

echo "Updating AUR packages"

for dir in ./*/ ; do
  (
    if [ -d "$dir" ]; then
      pkgdir=$(realpath "$dir")
      pkgname=$(basename "$pkgdir")
      echo -e "\n\e[1;34m==>\e[0m Updating aur/$pkgname"
      cd "$pkgdir" || exit 1

      shellcheck --shell=bash --exclude=SC2034,SC2154,SC2164,SC2148 PKGBUILD && echo "✅ PKGBUILD has valid bash syntax" || (echo "❌ PKGBUILD issues found"; exit 1)
      namcap PKGBUILD && echo "✅ PKGBUILD has valid format" || (echo "❌ PKGBUILD issues found"; exit 1)

      tmpdir=$(mktemp -d)
      cp -r ./ "$tmpdir" 
      cd "$tmpdir" || exit 1
      pkgctl version upgrade 2>&1 | grep -E "upgraded from|is latest" | xargs -rI{} echo "✅ pkgctl:" {}
      cp "$tmpdir/PKGBUILD" "$pkgdir/PKGBUILD"
      rm -rf "$tmpdir"

      
      cd "$pkgdir" || exit 1
      makepkg --printsrcinfo > .SRCINFO && echo "✅ .SRCINFO updated" || (echo "❌ Error updating .SRCINFO"; exit 1)

      echo -e "\e[1;32m===>\e[0m GitHub"
      git add .
      git commit -m "Version bump" | cat
      git push -u origin master && echo "✅ Package pushed to GitHub" || echo "❌ Error pushing to GitHub"

      echo -e "\e[1;32m===>\e[0m AUR"
      git push -u aur master && echo "✅ Package pushed to AUR" || echo "❌ Error pushing to AUR"
    fi
  )
done