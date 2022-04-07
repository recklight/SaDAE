#!/usr/bin/env python
# coding: utf-8
import argparse
import matplotlib.pyplot as plt
import hdf5storage
import numpy as np
import os
import scipy.io
import tensorflow as tf
from os.path import join
from keras.callbacks import ModelCheckpoint
from keras.models import Sequential, Model, load_model
from keras.layers import Dense, Dropout, Input, concatenate
from keras.optimizers import SGD, Adam, Nadam
from keras.utils import to_categorical
os.environ['TF_CPP_MIN_LOG_LEVEL'] = "2"
config = tf.ConfigProto()
config.gpu_options.allow_growth = True
sess = tf.Session(config=config)

class SEaDAE:
    def __init__(self):
        self.MdName = args.MdName
        self.data_dir = args.data_dir
        # Spk
        self.spk_model = Sequential()
        self.spk_model.add(Dense(units=1024, input_dim=2827, kernel_initializer='normal', activation='relu', name="dense_1"))
        self.spk_model.add(Dense(units=1024, kernel_initializer='normal', activation='relu', name="dense_2"))
        self.spk_model.add(Dense(units=1024, kernel_initializer='normal', activation='relu', name="dense_3"))
        self.spk_model.add(Dense(units=463, kernel_initializer='normal', activation='softmax', name="dense_4"))
        nadam = Nadam(lr=0.0001, beta_1=0.9, beta_2=0.999, epsilon=1e-08, schedule_decay=0.004)
        self.spk_model.compile(loss='categorical_crossentropy', optimizer=nadam, metrics=['accuracy'])

        # SpE
        main_input = Input(shape=(2827,), dtype='float32', name='main_input')
        sp_input = Input(shape=(1024,), name='sp_input')
        x = Dense(2048, kernel_initializer='normal', activation='sigmoid', name="se_dense_1")(main_input)
        x = Dropout(0.4)(x)
        x = Dense(2048, kernel_initializer='normal', activation='sigmoid', name="se_dense_2")(x)
        x = Dropout(0.4)(x)
        x = concatenate([x, sp_input])
        x = Dense(2048, kernel_initializer='normal', activation='sigmoid', name="se_dense_3")(x)
        x = Dropout(0.4)(x)
        # x = Dense(2048, kernel_initializer='normal', activation='sigmoid', name="se_dense_4")(x)
        # x = Dropout(0.67)(x)
        # x = Dense(2048, kernel_initializer='normal', activation='sigmoid', name="se_dense_5")(x)
        # x = Dropout(0.67)(x)
        main_output = Dense(257, kernel_initializer='normal', activation='linear', name='main_output')(x)
        self.SpE_model = Model(inputs=[main_input, sp_input], outputs=main_output)
        self.SpE_model.compile(
            loss={'main_output': 'mean_squared_error'},
            # loss_weights={'main_output': 1.},
            optimizer=Nadam(lr=0.0001, beta_1=0.9, beta_2=0.999, epsilon=1e-08, schedule_decay=0.004),
            metrics=['accuracy'])
    
    def load_train_indata(self):
        Traindata_dir = join(self.data_dir, 'TrainData_noisy.mat')
        Train_data_Noisy = hdf5storage.loadmat(Traindata_dir)
        self.Train_data_Noisy = Train_data_Noisy["indata"].astype('float32')

    def trainSpk(self):
        TrainLabelPath = join(self.data_dir, 'SpecPersonLabel.mat')
        Train_label = hdf5storage.loadmat(TrainLabelPath)
        Train_label = Train_label["SpecPersonLabel"].astype('int32')
        Train_label_OneHot = to_categorical(Train_label)

        checkpointer = ModelCheckpoint(
            filepath=join("model",self.MdName+"_Spk_model.hdf5"),
            monitor="val_accuracy",
            mode="max",
            verbose=1,
            save_best_only=True)

        train_history = self.spk_model.fit(
            self.Train_data_Noisy,
            Train_label_OneHot,
            batch_size=5120,
            epochs=args.spk_eps,
            verbose=1,
            callbacks=[checkpointer],
            validation_split=0.02,
            shuffle=True)

        self.show_train_history(train_history,'accuracy','val_accuracy')
   
    def trainSpE(self):
        # get sp_code
        model = load_model(join("model",self.MdName+"_Spk_model.hdf5"))
        dense3_layer_model = Model(inputs=model.input, outputs=model.get_layer('dense_3').output)
        sp_code = dense3_layer_model.predict(self.Train_data_Noisy)
        
        # load train outdata
        Outdata_dir = join(self.data_dir, 'TrainData_clean.mat')
        Out_data = hdf5storage.loadmat(Outdata_dir)
        Out_data = Out_data["outdata"].astype('float32')
        checkpointer = ModelCheckpoint(
            filepath=join("model",self.MdName+"_SpE_Model.hdf5"),
            monitor="loss",
            mode="min",
            verbose=1,
            save_best_only=True)

        hist = self.SpE_model.fit(
            {'main_input': self.Train_data_Noisy, 'sp_input': sp_code},
            {'main_output': Out_data},
            batch_size=5120,
            epochs=args.spe_eps,
            verbose=1,
            callbacks=[checkpointer],
            validation_split=0.02,
            shuffle=True)

        self.show_train_history(hist,'loss','val_loss')

    def test(self):
        Tsdata_dir = join(self.data_dir, 'TsNorNoisyData.mat')
        Test_data_Noisy = hdf5storage.loadmat(Tsdata_dir)
        Test_data_Noisy = Test_data_Noisy["TsNorNoisyData"].astype('float32')

        model = load_model(join("model",self.MdName+"_Spk_model.hdf5"))
        dense3_layer_model = Model(inputs=model.input, outputs=model.get_layer('dense_3').output)
        sp_code = dense3_layer_model.predict(Test_data_Noisy)
        model = load_model(join("model/",self.MdName+"_SpE_Model.hdf5"))

        ReconSpectrumPatch = [model.predict(
            {'main_input': Test_data_Noisy,
             'sp_input': sp_code},
            batch_size=5120, verbose=1)]
        ReconSpectrumPatch = np.array(ReconSpectrumPatch, dtype='float32')
        scipy.io.savemat('ReconSpectrumPatch.mat', {'ReconSpectrumPatch': ReconSpectrumPatch[0, :, :]})

    def show_train_history(self, train_history, metris1, metris2):
        plt.figure()
        plt.plot(train_history.history[metris1])
        plt.plot(train_history.history[metris2])
        plt.title(self.MdName+metris1)
        plt.ylabel(metris1)
        plt.xlabel('Epochs')
        plt.grid(True)
        plt.legend([metris1, metris2], loc='upper left')
        plt.savefig(join("model",self.MdName+metris1+'.png'), dpi=150)
        # plt.show()

    def retest(self):
        Tsdata_dir = join(self.data_dir, 'TsNorNoisyData.mat')
        Test_data_Noisy = hdf5storage.loadmat(Tsdata_dir)
        Test_data_Noisy = Test_data_Noisy["TsNorNoisyData"].astype('float32')

        model = load_model("./model/model_ck/re_Spk_model.hdf5")
        dense3_layer_model = Model(inputs=model.input, outputs=model.get_layer('dense_3').output)
        sp_code = dense3_layer_model.predict(Test_data_Noisy)
        model = load_model("./model/model_ck/re_SpE_Model.hdf5")

        ReconSpectrumPatch = [model.predict({'main_input': Test_data_Noisy,'speakercode_input': sp_code},batch_size=5120, verbose=1)]
        ReconSpectrumPatch = np.array(ReconSpectrumPatch, dtype='float32')
        scipy.io.savemat('ReconSpectrumPatch.mat', {'ReconSpectrumPatch': ReconSpectrumPatch[0, :, :]})

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SEaDAE Speech Enhancement with multiple DNN neural networks")
    parser.add_argument("--MdName", default="CK_SaDAE", type=str, help="proc name")
    parser.add_argument("--data_dir", default="./data/concat", type=str, help="data dir.")
    parser.add_argument("--spk_eps", default=30, type=int, help="Number of epochs to train Spk")
    parser.add_argument("--spe_eps", default=300, type=int, help="Number of epochs to train SpE")
    parser.add_argument("--retest", action='store_true')
    args = parser.parse_args()
    
    SEaDAE = SEaDAE()
    if args.testing:
        SEaDAE.retest()
    else:
        SEaDAE.load_train_indata()
        SEaDAE.trainSpk()
        SEaDAE.trainSpE()
        SEaDAE.test()
