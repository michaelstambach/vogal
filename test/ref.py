import pygame


# LEVEL = [25, 44, 30, 3, 3, 44, 22, 10, 13, 12, 51, 28, 44, 13, 6, 0]
# LEVEL = [0, 6, 13, 44, 28, 51, 12, 13, 10, 22, 44, 3, 3, 30, 33, 25]
LEVEL = [0, 50, 28, 44, 28, 51, 12, 13, 10, 22, 44, 3, 3, 30, 33, 25]

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
        elif keymap == 2: # down
            self.player_pos = (self.player_pos-1) % 54
        elif keymap == 1: # up
            self.player_pos = (self.player_pos+1) % 54

        if self.game_ongoing:
            # background
            self.screen.fill('blue')

            # pre calculate bird position for collision detection
            birdrect = pygame.Rect(95, self.player_pos<<3, 32, 32)
            collided = False

            # level / pipes
            pipe_idx = self.level_progress >> 6
            pipe_offset = self.level_progress & 0b0000_111111
            for i in range(3):
                ph = LEVEL[((pipe_idx+i)%16)]<<3
                uprect = pygame.Rect(i*256+127-(pipe_offset<<2), 0, 64, ph)
                downrect = pygame.Rect(i*256+127-(pipe_offset<<2), ph+64, 64, 480-ph-64)
                if i == 0:
                    collided = birdrect.colliderect(uprect) or birdrect.colliderect(downrect)
                pygame.draw.rect(self.screen, 'green', uprect)
                pygame.draw.rect(self.screen, 'green', downrect)

            # bird
            pygame.draw.rect(self.screen, 'red', birdrect)
            self.level_progress += 1

            # intersection check
            if collided:
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

def generate_frames(inputs):
    pygame.init()
    screen = pygame.Surface((640, 480))
    game = Game(screen)
    for i, input in enumerate(inputs):
        game.render_frame(input)
        pygame.image.save(screen, f"reference/frame{i}.png")

if __name__ == '__main__':
    generate_frames([0, 4, 1, 1, 1, 1, 1, 1])
    #main()
