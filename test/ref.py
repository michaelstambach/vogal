import pygame


# LEVEL = [25, 44, 30, 3, 3, 44, 22, 10, 13, 12, 51, 28, 44, 13, 6, 0]
# LEVEL = [0, 6, 13, 44, 28, 51, 12, 13, 10, 22, 44, 3, 3, 30, 33, 25]
#LEVEL = [0, 50, 28, 44, 28, 51, 12, 13, 10, 22, 44, 3, 3, 30, 33, 25]
LEVEL = int("6ff57cca59abf0d20e6c5b9b1d40874d", 16)

class Game():
    
    def __init__(self, screen):
        self.screen = screen
        self.game_ongoing = False
        self.player_pos = 0
        self.player_vel = 0
        self.level_idx1 = 0
        self.level_idx2 = 0
        self.level_offset = 0
    
    def render_frame(self, keymap):
        if keymap == 4: # start game
            self.game_ongoing = True
            self.level_offset = 32
            self.level_idx1 = 0
            self.level_idx2 = 0
            self.player_pos = 0
            self.player_vel = 0
        #elif keymap == 2: # down
            #self.player_pos = (self.player_pos-(1<<4)) % (448<<1)
        elif keymap == 1: # flap
            #self.player_pos = (self.player_pos+(1<<4)) % (448<<1)
            self.player_vel -= 4

        if self.game_ongoing:
            # background
            self.screen.fill('blue')

            # pre calculate bird position for collision detection
            birdrect = pygame.Rect(95, self.player_pos>>1, 32, 32)
            collided = False

            # level / pipes
            for i in range(3):
                ph = ((LEVEL >> (self.level_idx1 + 7*i)%64) & 0b11111111) + \
                     ((LEVEL >> (self.level_idx2 + 5*i)%64) & 0b1111111)
                uprect = pygame.Rect(i*256+127-(self.level_offset<<2), 0, 64, ph)
                downrect = pygame.Rect(i*256+127-(self.level_offset<<2), ph+96, 64, 480-ph-96)
                if i == 0:
                    collided = birdrect.colliderect(uprect) or birdrect.colliderect(downrect)
                pygame.draw.rect(self.screen, 'green', uprect)
                pygame.draw.rect(self.screen, 'green', downrect)

            # bird
            pygame.draw.rect(self.screen, 'red', birdrect)
            if self.level_offset == 63:
                self.level_offset = 0
                self.level_idx1 = (self.level_idx1 + 7) % 64
                self.level_idx2 = (self.level_idx2 + 5) % 64
            else:
                self.level_offset += 1

            # intersection check
            if collided:
                self.game_ongoing = False
            
            # update position
            self.player_pos += self.player_vel
            if self.player_pos < 0:
                self.player_pos = 0
            elif self.player_pos > 896:
                self.player_pos = 896
            self.player_vel += 1

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
        if keys[pygame.K_SPACE]:
            keymap += 1
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
    generate_frames([0, 4, 0, 0, 0, 0, 0, 0])
    #main()
