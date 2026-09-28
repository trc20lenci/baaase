#pragma once

#include <QString>

// Where the Addon Manager fetches from. Both values are configured in CMakeLists.txt
// (BASE_ADDON_INDEX_URL / BASE_ADDON_CLIENT_TOKEN) and injected as compile definitions — this
// header only reads them, so there is one place to change the service.
//
// The token is NOT a secret and is not treated as one: it ships inside every copy of BASE and
// anyone can pull it out of the binary. Its job is to stop the bucket being crawled or hotlinked,
// which would cost us operations for someone else's benefit. Rotate it by deploying a new Worker
// secret and shipping a new build; old builds then fall back to whatever they have installed.

// A translation unit built outside the `drift` target gets no service rather than a stale
// hardcoded one.
#ifndef BASE_ADDON_INDEX_URL
#define BASE_ADDON_INDEX_URL ""
#endif
#ifndef BASE_ADDON_CLIENT_TOKEN
#define BASE_ADDON_CLIENT_TOKEN ""
#endif

namespace drift::addon {

inline const QString kIndexUrl = QStringLiteral(BASE_ADDON_INDEX_URL);
inline const QString kClientToken = QStringLiteral(BASE_ADDON_CLIENT_TOKEN);

// False when the build was configured with an empty index URL. The manager then lists nothing and
// installs nothing; anything already installed, side-loaded, or pointed at by BASE_*_DIR still
// works, since those paths never involve the service.
inline bool addonServiceConfigured()
{
    return !kIndexUrl.isEmpty();
}

} // namespace drift::addon
