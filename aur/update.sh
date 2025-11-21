#!/bin/bash

echo "Updating AUR packages"

for dir in ./*/ ; do
    (
        if [ -d "$dir" ]; then
            pkgdir=$(realpath "$dir")
            pkgname=$(basename "$pkgdir")
            echo "==> Updating aur/$pkgname"
            cd "$pkgdir"

            echo "Checking validity of PKGBUILD"
            namcap PKGBUILD

            echo "Checking for version updates"
            tmpdir=$(mktemp -d)
            echo "$tmpdir"
            cp -r ./ "$tmpdir"
            cd "$tmpdir"
            pkgctl version upgrade
            cp "$tmpdir/PKGBUILD" "$pkgdir/PKGBUILD"
            rm -rf "$tmpdir"

            echo "Updating .SRCINFO"
            cd "$pkgdir"
            makepkg --printsrcinfo > .SRCINFO

            echo "Committing and pushing changes"
            git add .
            git commit -m "Version bump"
            git remote | xargs -L1 git push --all
        fi
    )
done