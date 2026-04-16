//
//  CarPlaySceneDelegate.swift
//  MusicPlayer
//
//  CarPlay 车载播放支持
//

import CarPlay
import MediaPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    var interfaceController: CPInterfaceController?

    private var playerService: MusicPlayerService { MusicPlayerService.shared }
    private var libraryService: MusicLibraryService { MusicLibraryService.shared }

    // MARK: - CPTemplateApplicationSceneDelegate

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeTabBarTemplate(), animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    // MARK: - Root Template

    private func makeTabBarTemplate() -> CPTabBarTemplate {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        nowPlayingTemplate.isUpNextButtonEnabled = true
        nowPlayingTemplate.isAlbumArtistButtonEnabled = true

        let songsTemplate = makeSongsTemplate()
        let playlistsTemplate = makePlaylistsTemplate()

        return CPTabBarTemplate(templates: [nowPlayingTemplate, songsTemplate, playlistsTemplate])
    }

    // MARK: - Songs List

    private func makeSongsTemplate() -> CPListTemplate {
        let songs = libraryService.songs
        let items = songs.map { song -> CPListItem in
            let item = CPListItem(text: song.title, detailText: song.displayArtist)
            item.handler = { [weak self] _, completion in
                self?.playerService.play(song: song, in: songs)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "歌曲", sections: [section])
        template.tabImage = UIImage(systemName: "music.note")
        return template
    }

    // MARK: - Playlists

    private func makePlaylistsTemplate() -> CPListTemplate {
        let playlists = libraryService.playlists
        let items = playlists.map { playlist -> CPListItem in
            let item = CPListItem(
                text: playlist.name,
                detailText: "\(playlist.songs.count) 首歌曲"
            )
            item.handler = { [weak self] _, completion in
                guard let self else { completion(); return }
                let detail = self.makePlaylistDetailTemplate(playlist: playlist)
                self.interfaceController?.pushTemplate(detail, animated: true, completion: nil)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "歌单", sections: [section])
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }

    private func makePlaylistDetailTemplate(playlist: Playlist) -> CPListTemplate {
        let songs = playlist.songs
        let items = songs.map { song -> CPListItem in
            let item = CPListItem(text: song.title, detailText: song.displayArtist)
            item.handler = { [weak self] _, completion in
                self?.playerService.play(song: song, in: songs)
                completion()
            }
            return item
        }

        let section = CPListSection(items: items)
        return CPListTemplate(title: playlist.name, sections: [section])
    }
}
