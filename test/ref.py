import pygame


LEVEL = [0, 44, 30, 3, 3, 44, 22, 10, 13, 12, 51, 28, 44, 13, 6, 25]

class Game():
    
    def __init__(self, screen):
        self.screen = screen
        self.game_ongoing = False
        self.player_pos = LEVEL[0]
        self.level_progress = 0
    
    def render_frame(self, keymap):
        if keymap == 4: # start game
            self.game_ongoing = True
            self.level_progress = 0
            self.player_pos = LEVEL[0]
        elif keymap == 2: # up
            self.player_pos = (self.player_pos+1) % 54
        elif keymap == 1: # down
            self.player_pos = (self.player_pos-1) % 54

        if self.game_ongoing:
            # background
            self.screen.fill('blue')

            # level / pipes
            pipe_idx = self.level_progress >> 6
            pipe_offset = self.level_progress & 0b0000_111111
            for i in range(3):
                ph = LEVEL[((pipe_idx+i)%16)]<<3
                uprect = pygame.Rect(i*256+128-(pipe_offset<<2), 0, 64, ph)
                downrect = pygame.Rect(i*256+128-(pipe_offset<<2), ph+64, 64, 480-ph-64)
                pygame.draw.rect(self.screen, 'green', uprect)
                pygame.draw.rect(self.screen, 'green', downrect)

            # bird
            birdrect = pygame.Rect(96, self.player_pos<<3, 32, 32)
            pygame.draw.rect(self.screen, 'red', birdrect)
            self.level_progress += 1

            # intersection check
            intersecth = pipe_offset < 32 and pipe_offset > 8
            fph = LEVEL[(pipe_idx%16)]
            intersectv = self.player_pos < fph or self.player_pos > (fph + 4)
            if intersectv and intersecth:
                self.game_ongoing = False

        else:
            self.screen.fill('red')



def main():
    pygame.init()
    screen = pygame.display.set_mode((640, 480))
    game = Game(screen)
    clock = pygame.time.Clock()
    running = True

    while running:
        # main game loop, one iteration per frame
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # buttons
        keys = pygame.key.get_pressed()
        # this is kinda silly but more like hardware
        keymap = 0
        if keys[pygame.K_UP]:
            keymap += 1
        if keys[pygame.K_DOWN]:
            keymap += 2
        if keys[pygame.K_RETURN]:
            keymap += 4

        game.render_frame(keymap)

        pygame.display.flip()

        clock.tick(30)
    
    pygame.quit()

def generate_frames(framecount, inputs):
    assert len(inputs) == framecount

if __name__ == '__main__':
    main()
