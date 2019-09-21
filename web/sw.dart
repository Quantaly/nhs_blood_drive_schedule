import 'package:service_worker/worker.dart' as w;

const cacheName = "bd-cache-v1";

const cacheResources = [
  // page data
  ".",
  "index.html",
  "styles.css",
  "main.dart.js",
  "manifest.json",

  // icons
  "icons/icon-192.png",
  "icons/icon-512.png",
  "icons/icon-ios.png",

  // fonts
  "https://fonts.googleapis.com/icon?family=Material+Icons&display=swap",
  "https://fonts.googleapis.com/icon?family=Crimson+Text&display=fallback",
];

void main() {
  w.onInstall.listen((evt) {
    evt.waitUntil(() async {
      var cache = await w.caches.open(cacheName);
      await cache.addAll(cacheResources);
    }());
  });

  w.onActivate.listen((evt) {
    evt.waitUntil(() async {
      var futures = <Future>[];
      for (var cache in await w.caches.keys()) {
        if (cache != cacheName) {
          futures.add(w.caches.delete(cache));
        }
      }
      await Future.wait(futures);
    }());
  });

  w.onFetch.listen((evt) {
    evt.respondWith(w.caches.match(evt.request).then((resp) {
      if (resp != null) {
        return resp;
      } else {
        return w.fetch(evt.request).then((resp) {
          if (resp == null ||
              resp.status != 200 ||
              !{"basic", "cors"}.contains(resp.type)) {
            return resp;
          }

          var toCache = resp.clone();
          w.caches.open(cacheName).then((cache) {
            cache.put(evt.request, toCache);
          });
          return resp;
        });
      }
    }));
  });
}
